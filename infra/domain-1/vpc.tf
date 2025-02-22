# ********** Dedicated VPN for EKS Cluster *****************
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "main"
  }
}


#******* Private Subnets **********
# -> used for woker nodes to ensure that workloads runs securely,
# -> isolated form direct access, to and from internet. 
# -> connects to the internet throught a Nat Gateway, allowing 
# -> outbound traffic ( e.g pulling container images ) without exposing 
# -> nodes to the inbound traffic.
resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, var.private_subnet_additional_bits, count.index + var.public_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name                                        = "private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

#****** Private Subnets *************
# -> Utilized for resources that need to be accessible from the internet,
# -> like ELBs that need to route traffic to the internal services.
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, var.public_subnet_additional_bits, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name                                        = "public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# *********** Internet gateway *********
# -> enables services in public subnet to connect to the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# ***** Elastic IP *************
# -> Elastic IP address for the NAT gateway, to route outbound traffic 
# -> from The NAT Gateway.
resource "aws_eip" "nat_gateway" {
  count = var.nat_gateway ? 1 : 0

  domain = "vpc"
}

# *********** NAT Gateway **************
# -> A Network Address Translation gateway enable instances in private subnet to initiate
# -> outbound traffic to the internet for (updates, download software, etc.),
# -> Without allowing inbound traffic form the internet.
# -> helps maintaining security and integrity for k8s nodes, ensures they have access
# -> to necessary resources.
resource "aws_nat_gateway" "main" {
  count = var.nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_gateway[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "main-natgateway-default"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# ********* Rounte table *************
# ->  Route tables in AWS VPC define rules, which determine where network
# -> traffic from the subnet or gateway is directed.
# -> In the context of EKS:

# ********* Public route table *************
# -> Directs traffic from the public subnet to the internet gateway, 
# -> allowing resources in the public subnet ( like ELBs ) to be accessible form the internet. 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-route-table"
  }
}

# ****** Public Route Table rules *********
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

# ****** Public Route table associations *****
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ************ Private route table *****************
# -> Uses the NAT for the routing outbound form private subnets,
# -> esuring that worker nodes can access the internet for essential tasks
# -> while remaining unreachable directly from the internet.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table"
  }
}

# ****** Private route table rule *****************
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = var.nat_gateway ? aws_nat_gateway.main[0].id : null
  destination_cidr_block = "0.0.0.0/0"
}

#********* Private Route table associations *********
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# *************** AZs ***********
# -> read azs from current region.
data "aws_availability_zones" "available" {
  state = "available"
}
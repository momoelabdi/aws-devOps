# Adopt default aws vpc
data "aws_vpc" "default" {
  default = true
}

# ******** Available AZs ***********
data "aws_availability_zones" "azs" {
  state = "available"
}

# Adopt default security group 
resource "aws_default_security_group" "main" {
  vpc_id = data.aws_vpc.default.id
}

# ***** Internet Gateway ***********
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.default.id
  tags   = { Name = "eks-igw" }
}

# ****** Elastic IP ***********
resource "aws_eip" "eip" { domain = "vpc" }

# ******* Nat Getway *************
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "eks-natgateway" }
}

# ********* Public Subnet *****************
resource "aws_subnet" "public" {
  count             = var.public_subnets
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}
# ********* Public  route table **********
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  tags   = { Name = "public-route-table" }
}

# ********* Public route ******************
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# ******** Public route  association ***********
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ******** Private Subnets *************
resource "aws_subnet" "private" {
  count             = var.private_subnets
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index + var.private_subnets)
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  tags              = { Name = "private-subnet-${count.index}" }
}

# ******* Private route table ********
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  tags   = { Name = "private-route-table" }
}

# ******* Private route **********
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.ngw.id
  destination_cidr_block = "0.0.0.0/0"
}

# ******** Private route table association *******
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

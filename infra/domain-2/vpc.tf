
# ******* ECS VPC *******

#-> read the deafult vpc 
data "aws_vpc" "default" {
  default = true
}

#-> read azs on current region 
data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = var.subnet_count
  vpc_id                  = data.aws_vpc.default.id
  availability_zone       = data.aws_availability_zones.azs.names[count.index]
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, var.subnet_additional_bits, count.index + var.subnet_count)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "private" {
  count             = var.subnet_count
  vpc_id            = data.aws_vpc.default.id
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, var.subnet_additional_bits, count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

#-> TODO routing tables + associations 

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ntgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = "igw-main"
  }
}
# *************** Public route tables rules **************
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ************ Private route tables roules **********
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.ntgw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
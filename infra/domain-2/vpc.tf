
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
  cidr_block              = cidrsubnet(var.cidr_block, var.subnet_additional_bits, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = var.subnet_count
  vpc_id            = data.aws_vpc.default.id
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, var.subnet_additional_bits, count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

#-> TODO routing tables + associations 
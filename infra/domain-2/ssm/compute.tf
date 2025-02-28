
provider "aws" { region = "eu-central-1" }

# Adopt default vpc 
data "aws_vpc" "default" {
  default = true
}

# generate an SSH key for instances
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA" # use rsa algorithm
  rsa_bits  = 2048  # define the rsa bits to use 
}

# create an aws SSH key pair for authentication 
resource "aws_key_pair" "ssh_key" {
  key_name   = "instance_key"
  public_key = tls_private_key.ssh_key.public_key_openssh # use the generated public key 
}

# ec2 instance to apply patches via ssm 
resource "aws_instance" "ssm" {
  ami                         = "ami-0745b7d4092315796"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.instance_ssm_profile.name
  vpc_security_group_ids      = [aws_default_security_group.default.id]
  subnet_id                   = aws_subnet.sbt.id
  # user_data = file("${path.module}/scripts/ec2-startup.sh")

  tags = {
    Name       = "ec2-ssm-target"
    PatchGroup = "ubuntu-servers"
  }
}

# SSM Agent is insalled by default on current OS ( ubuntu ).
# Need just permision to connect to ssm agent, here we go.
resource "aws_iam_instance_profile" "instance_ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

# -> Adopt default security group 
resource "aws_default_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  dynamic "ingress" {
    for_each = [80, 443, 22]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# single public subnet for the ec2
resource "aws_subnet" "sbt" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = data.aws_vpc.default.cidr_block
  tags = {
    Name = "Sbt-subnet"
  }
}

# create IGW for the ec2 
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = "igw-main"
  }
}

# public route table 
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
  subnet_id      = aws_subnet.sbt.id
  route_table_id = aws_route_table.public.id
}

# ssh key output 
output "private_key" {
  description = "Private SSH key"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

# write public ip to file 
resource "local_file" "ec2_ssm_public_ip" {
  filename = "${path.module}/ec2_ssm_public_ip.txt"
  content  = aws_instance.ssm.public_ip
}
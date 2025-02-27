# ************** SG for ECS **********
# -> Managing the default security group,
# -> it immediately removes all ingress and egress rules in the Security Group.
# -> It then creates these rules specified in the configuration.
# -> This way only the rules specified in these configuration are created.
resource "aws_default_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  dynamic "ingress" {
    for_each = [80, 443]
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
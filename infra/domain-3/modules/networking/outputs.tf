
######## Private subnets Ids #############
output "private_subnets_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

########## VPC ID ##########
output "vpc_id" {
  description = "Current VPC ID"
  value = data.aws_vpc.default.id 
}


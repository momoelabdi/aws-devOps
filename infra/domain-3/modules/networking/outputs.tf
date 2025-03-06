
######## Private subnets Ids #############
output "private_subnets_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

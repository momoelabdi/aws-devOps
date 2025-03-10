
variable "db_subnet_name" {
  type        = string
  description = "DB Subnet Name"
}

variable "private_subnets_ids" {
  type        = list(string)
  description = "Private Subnets IDs"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "db_instance_type" {
  type        = string
  description = "Instance type to use for the DB."
}

variable "db_identifier" {
  type        = string
  description = "Postgresql DB identifier"
}

variable "db_username" {
  type        = string
  description = "Db root username"
}

variable "db_password" {
  type        = string
  description = "Db root user password"
}


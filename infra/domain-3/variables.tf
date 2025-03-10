variable "worker_instance_type" {
  type        = string
  default     = "t2.medium"
  description = "Workers instance type"
}

variable "eks_node_group_name" {
  type        = string
  default     = "eks-node-group"
  description = "EKS node group Name"
}

variable "cluster_name" {
  type        = string
  default     = "eks-cluster"
  description = "EKS cluster Name"
}
variable "db_subnet_name" {
  type        = string
  default     = "db-subnet"
  description = "DB Subnet Name"
}

variable "db_instance_type" {
  type        = string
  default     = "db.t3.micro"
  description = "Instance type to use for the DB."
}

variable "db_identifier" {
  type        = string
  default     = "db-postgres"
  description = "Postgresql DB identifier"
}
variable "db_username" {
  type        = string
  default     = "echo_sphere"
  description = "Db root username"
}

variable "db_password" {
  type        = string
  default     = "echo_sphere_password"
  description = "Db root user password"
}
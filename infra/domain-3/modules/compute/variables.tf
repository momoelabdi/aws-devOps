
variable "cluster_name" {
  type        = string
  description = "EKS cluster Name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "description"
}

variable "eks_node_group_name" {
  type        = string
  description = "EKS node group Name"
}

variable "worker_instance_type" {
  type        = string
  description = "Workers instance type"
}

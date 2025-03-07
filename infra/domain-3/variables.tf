variable worker_instance_type {
  type        = string
  default = "t2.medium"
  description = "Workers instance type"
}

variable eks_node_group_name {
  type        = string
  default = "eks-node-group"
  description = "EKS node group Name"
}

variable "cluster_name" {
  type        = string
  default = "eks-cluster"
  description = "EKS cluster Name"
}

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
variable "load_balancer_controller_name" {
  type        = string
  default     = "aws-load-balancer-controller"
  description = "AWS Load balnncer controller"
}

variable "load_balancer_repo_url" {
  type        = string
  default     = "https://aws.github.io/eks-charts"
  description = "description"
}
variable "load_balancer_image" {
  type        = string
  default     = "602401143452.dkr.ecr.ca-central-1.amazonaws.com/amazon/aws-load-balancer-controller"
  description = "description"
}

variable region {
  type        = string
  default     = "eu-central-1"
  description = "AWS Region"
}

variable vpc_id {
  type        = string
  description = "AWS VPC ID"
}

variable api_version {
  type        = string
  default     = "client.authentication.k8s.io/v1beta1"
  description = "description"
}

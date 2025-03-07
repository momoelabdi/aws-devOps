variable "cluster_name" {
  type        = string
  description = "EKS cluster Name"
}

variable "public_subnets" {
  type        = number
  description = "Number of public sunbets to provision"
}

variable "private_subnets" {
  type        = number
  description = "Number of private sunbets to provision"
}

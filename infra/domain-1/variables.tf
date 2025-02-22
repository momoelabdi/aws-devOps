# ********************| _VARS_ | ****************************
variable "pipline_name" {
  type    = string
  default = "DomainOnePipline"
}
variable "repository_owner" {
  type    = string
  default = "simoelabdi"
}
variable "repository_name" {
  type    = string
  default = "echo_sphere"
}
variable "branch_name" {
  type    = string
  default = "main"
}
variable "bucket_name" {
  type    = string
  default = "codepipeline-bucket"
}
variable "ecr_repository_name" {
  type    = string
  default = "domain1_repositories"
}
variable "codebuild_project_name" {
  type    = string
  default = "DomainOneProject"
}
variable "docker_image_tag" {
  type    = string
  default = "latest"
}
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type        = string
  default     = "eks-cluster"
  description = "EKS cluster name"
}

variable "node_gname" {
  type        = string
  default     = "node-group"
  description = "description"
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The IPv4 CIDR block for the VPC."
  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}
variable "public_subnet_count" {
  type        = number
  default     = 3
  description = "Number of Public subnets."
}

variable "public_subnet_additional_bits" {
  type        = number
  default     = 4
  description = "Number of additional bits with which to extend the prefix."
}

variable "private_subnet_count" {
  type        = number
  default     = 3
  description = "Number of Private subnets."
}

variable "private_subnet_additional_bits" {
  type        = number
  default     = 4
  description = "Number of additional bits with which to extend the prefix."
}
variable "nat_gateway" {
  type        = bool
  default     = true
  description = "A boolean flag to deploy NAT Gateway."
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

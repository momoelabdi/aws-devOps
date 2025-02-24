# ******** ECS Vars ***********
variable "ecs_cluster_name" {
  type        = string
  default     = "ecs-cluster"
  description = "ECS cluster name"
}


variable "cidr_block" {
  type        = string
  default     = "172.20.0.0/24"
  description = "The IPv4 CIDR block for the VPC."
  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "Must be a valid IPv4 CIDR block address."
  }
}

variable "subnet_count" {
  type        = number
  default     = 3
  description = "Number of subnets for each of ( private & public )"
}

variable "subnet_additional_bits" {
  type        = number
  default     = 4
  description = "Additional bits to extend subnets prefix"
}



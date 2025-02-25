# ******** ECS Vars ***********
variable "ecs_cluster_name" {
  type        = string
  default     = "ecs-cluster"
  description = "ECS cluster name"
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



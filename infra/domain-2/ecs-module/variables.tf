# ******** ECS Vars ***********
variable "region" {
  type        = string
  description = "Region target"
}

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
  description = "Additional bits to extend subnets prefix"
}

variable "service_name" {
  type        = string
  default     = "jenkins-service"
  description = "ECS Service Name"
}
variable "image_name" {
  type = string
  description = "Jenkins docker image to deploy"
}

variable "container_name" {
  type        = string
  default     = "jenkins"
  description = "Docker container name"
}

variable "autoscaling_gname" {
  type        = string
  default     = "esc-autoscaling-group"
  description = "description"
}

variable "instance_type" {
  type = string
  description = "type of instance for autoscalling group to start"
}


variable "max_size" {
  type = number
  description = "Max number of instances to deploy"
}

variable "min_size" {
  type = number
  description = "Min number of instances to deploy"
}

variable "desired_capacity" {
  type = number
  description = "Desired number of instances to be runing"
}
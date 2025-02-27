
#**** Deploy the ECS cluster to a specific region **** ( eu-west-1 )
module "ecs" {
  source           = "../../ecs-module"
  region           = "eu-west-1"
  image_name       = "jenkins/jenkins:lts"
  instance_type    = "t2.micro"
  subnet_additional_bits = 8
  max_size         = 2
  min_size         = 1
  desired_capacity = 1
}

# ****** ECS Cluster ********

# ECS cluster 
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

# ******* ECS service ******** 
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "EC2"
  desired_count   = 2
}

resource "aws_ecs_task_definition" "task" {
  family = "unique-family-name"
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "nginx"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ***** autoscalling group **************
resource "aws_autoscaling_group" "ecs_asg" {
  name             = "ecs_asg"
  max_size         = 2
  min_size         = 1
  desired_capacity = 1
  # vpc_zone_identifier = TODO -> *subnets*
  health_check_type = "EC2"


  launch_template {
    id = aws_launch_template.ecs_tpl.id
  }

  tag {
    key                 = "Name"
    value               = "${var.ecs_cluster_name}-ASG"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "ecs_tpl" {
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = "t2.micro"

  # TODO -> vpc_security_group_ids  = [SG] 

  user_data = base64encode(templatefile("${path.module}/../../scripts/ecs_init.sh", {
    ecs_cluster_name = aws_ecs_cluster.ecs_cluster.name
  }))

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  # name "ec2_Role_Profile"
  role = aws_iam_role.ecs_node_role.id
}

# read image ID from system manager agent
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}


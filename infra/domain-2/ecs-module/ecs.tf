# ****** ECS Cluster ********

# ECS cluster 
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

# ******* ECS service ******** 
resource "aws_ecs_service" "ecs_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "EC2"
  desired_count   = 1
}

resource "aws_ecs_task_definition" "task" {
  family             = "unique-family-name"
  task_role_arn      = aws_iam_role.tasks_role.arn
  execution_role_arn = aws_iam_role.execution_tasks_role.arn
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image_name
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])
}

# ***** autoscalling group **************
resource "aws_autoscaling_group" "ecs_asg" {
  name                = var.autoscaling_gname
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = aws_subnet.public[*].id
  health_check_type   = "EC2"

  launch_template {
    id = aws_launch_template.ecs_tpl.id
  }
}

#*****  Connect ECS cluster to the autoscaling group ******
# -> allows cluster to use the EC2s to deploy containers. 
resource "aws_ecs_capacity_provider" "main" {
  name = "cluster-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_cp" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

# ***** Launch template for the EC2 instances ******
# -> where containers will be running 
resource "aws_launch_template" "ecs_tpl" {
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = var.instance_type

  # TODO -> vpc_security_group_ids  = [SG] 

  user_data = base64encode(templatefile("${path.module}/../../../scripts/ecs_init.sh", {
    ecs_cluster_name = aws_ecs_cluster.ecs_cluster.name
  }))

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_Role_Profile"
  role = aws_iam_role.ecs_node_role.id
}

# read image ID from system manager agent
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# ********** Container servive Cloudwatch Logs ******************
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 14
}

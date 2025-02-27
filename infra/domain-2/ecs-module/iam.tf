
# ****** IAM for ECS *******

# **** ECS node role ********
resource "aws_iam_role" "ecs_node_role" {
  name               = "ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}


data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_attach" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


# ***** ECS tasks execution role ***********
resource "aws_iam_role" "execution_tasks_role" {
  name               = "TaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task_assume_policy.json
}

resource "aws_iam_role" "tasks_role" {
  name               = "TasksIamRole"
  assume_role_policy = data.aws_iam_policy_document.task_assume_policy.json
}

data "aws_iam_policy_document" "task_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.execution_tasks_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


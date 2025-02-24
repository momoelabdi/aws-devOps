
# ****** IAM for ECS *******

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
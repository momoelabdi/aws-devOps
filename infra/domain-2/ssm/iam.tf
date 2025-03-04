# allow ec2 instance to communicate with ssm
resource "aws_iam_role" "ssm_role" {
  name               = "SSMPatchRole"
  assume_role_policy = data.aws_iam_policy_document.ssm_role_document.json
}

data "aws_iam_policy_document" "ssm_role_document" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ssm.amazonaws.com"]
    }
  }
}

# attach the aws ssm managed role to ec2.
resource "aws_iam_role_policy_attachment" "ssm_role_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ssm_full_access_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# -> write ECR repository to save docker image built in build stage of codepipline
resource "aws_ecr_repository" "repository" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
}

# -> configure codebuild project to execute in build satge
resource "aws_codebuild_project" "code_build" {
  name         = var.codebuild_project_name
  service_role = aws_iam_role.codebuild_role.arn

  #-> read artifact from the Source satge output ( s3 bucket )
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.repository.repository_url
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "CLUSTER_NAME"
      value = var.cluster_name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = var.docker_image_tag
    }
    environment_variable {
      name  = "VPC_ID"
      value = aws_vpc.main.id
    }
  }

  # -> buildspec should be part of the repository to be deployed 
  source {
    type      = "CODEPIPELINE"
    buildspec = file("../../scripts/buildspec.yml")
  }
}


# **************** Codebuild IAM ******************************

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "CreatedCodeBuildPolicy"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_role" "codebuild_role" {
  name               = "CreatedCodeBuildRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

# -> write service role for codebuild
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codebuild_policy" {
  #-> allow codebuild to create logs on scripts execution 
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  #-> allow codebuild read, write to ECR docker images 
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:CompleteLayerUpload",
      "ecr:GetRepositoryPolicy",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = ["${aws_ecr_repository.repository.arn}", "*"]
  }

  #-> allow codebuild to read codepipline output from s3
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning"
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }
  #-> allow codebuild to check cluster availibilty 
  statement {
    effect = "Allow"
    actions = [
      "eks:ListNodegroups",
      "eks:DescribeNodegroup"
    ]
    resources = [
      aws_eks_cluster.master.arn,
      aws_eks_node_group.nodes.arn
    ]
  }
}

#-> attach managed policies ( ec2, cni, eksWorker ) to build role 
resource "aws_iam_role_policy_attachment" "build_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "buildec2_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "buildeks_cni_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
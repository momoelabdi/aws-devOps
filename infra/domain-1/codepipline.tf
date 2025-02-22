#******* CodePipline stages *************
# ****** Source Stage: ********
# -> checkout source code form github 
# -> store source code as artifact in s3 bucket 
# ** Build Stage: **
# -> read source code from first stage output ( s3 )
# -> build docker image of the source code 
# -> push docker image to ECR registry
# -> deploy latest Changes 
resource "aws_codepipeline" "codepipeline" {
  name          = var.pipline_name
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["Source"]
      configuration = {
        Owner      = var.repository_owner
        Repo       = var.repository_name
        Branch     = var.branch_name
        OAuthToken = jsondecode(data.aws_secretsmanager_secret_version.github.secret_string)["github_token"]
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.code_build.name
      }
    }
  }
  depends_on = [aws_eks_cluster.master]
}


# *********** Pipline Artifact Storage **************
# create s3 bucket to store artifacts 
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.bucket_name}-${uuid()}"
}

# block public access to artifacts bucket
resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ****************** CodePipline IAM *************************
# -> creates IAM Service role for codePipline with permissions to:
# -> save stages ouputs to S3 bucket. 
# -> trigger build stage on codebuild.
# -> read source code access key from secrets manager.
resource "aws_iam_role" "codepipeline_role" {
  name               = "CreatedCodePiplineRole"
  assume_role_policy = data.aws_iam_policy_document.pipline_assume_role.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "CreatedCodepipelinePolicy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


data "aws_iam_policy_document" "codepipeline_policy" {
  #-> allow pipline to read and edit s3 bucket content
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  #-> allow pipline to delegate next stage to codebuild service.
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = ["*"]
  }

  #-> allow pipline to read required access keys from secret manager
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = ["*"]
  }
}

# -> iam service role for codepipline service.
data "aws_iam_policy_document" "pipline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ****************** CodePipline Secrets ( github ) *************************
# -> find github token by name om secret manager
data "aws_secretsmanager_secret" "by_name" {
  name = "githubToken"
}

# -> read github token version from secret manager
data "aws_secretsmanager_secret_version" "github" {
  secret_id = data.aws_secretsmanager_secret.by_name.id
}

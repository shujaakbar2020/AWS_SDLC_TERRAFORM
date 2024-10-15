resource "aws_s3_bucket" "demo" {
  bucket = var.code_build_s3_bucket
}

resource "aws_s3_bucket_ownership_controls" "demo" {
  bucket = aws_s3_bucket.demo.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "demo" {
  depends_on = [aws_s3_bucket_ownership_controls.demo]

  bucket = aws_s3_bucket.demo.id
  acl    = "private"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "demo" {
  name               = "demo"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "demo" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "demo" {
  role   = aws_iam_role.demo.name
  policy = data.aws_iam_policy_document.demo.json
}

resource "aws_codebuild_project" "demo" {
  name          = var.code_build_name
  description   = "test_codebuild_project"
  build_timeout = 5
  service_role  = aws_iam_role.demo.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.demo.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPO"
      value = "value1"
    }
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/${var.code_build_name}-logs"
      stream_name = "${var.code_build_name}-build-log-stream"
    }

    s3_logs {
      status   = "DISABLED"
      # location = "${aws_s3_bucket.demo.id}/build-log"
    }
  }

  source {
    type            = "CODEPIPELINE"
    location        = var.github_repository_link
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = var.github_branch_name

  # vpc_config {
  #   vpc_id = aws_vpc.demo.id

  #   subnets = [
  #     aws_subnet.subnet1.id,
  #     aws_subnet.subnet2.id,
  #   ]

  #   security_group_ids = [
  #     aws_security_group.ecs_sg.id,
  #   ]
  # }

  tags = {
    Environment = "stage"
  }
}

# CodeBuild Source Credential for GitHub Authentication
resource "aws_codebuild_source_credential" "github_credential" {
  auth_type     = "PERSONAL_ACCESS_TOKEN"
  server_type   = "GITHUB"
  token         = data.aws_secretsmanager_secret_version.github_token_version.secret_string  # Token stored in AWS Secrets Manager
}

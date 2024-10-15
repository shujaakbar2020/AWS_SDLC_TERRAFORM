resource "aws_codepipeline" "codepipeline" {
  name     = var.code_pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_username
        Repo       = var.github_repository_name
        Branch     = var.github_branch_name
        OAuthToken = data.aws_secretsmanager_secret.github_token.id
      }
    }
  }

  # Build Stage
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.demo.name
      }
    }
  }

  # Deploy to Dev Stage
  stage {
    name = "DeployToDev"

    action {
      name            = "DeployDev"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName        = aws_ecs_cluster.ecs_cluster.name
        ServiceName        = aws_ecs_service.dev_ecs_service.name
        FileName           = "imagedefinitions.json"
      }
    }
  }

  # Deploy to Stage
  stage {
    name = "DeployToStage"

    action {
      name            = "DeployStage"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName        = aws_ecs_cluster.ecs_cluster.name
        ServiceName        = aws_ecs_service.stage_ecs_service.name
        FileName           = "imagedefinitions.json"
      }
    }
  }

  # Optional Manual Approval before Production Deployment
  stage {
    name = "Approval"

    action {
      name     = "ApproveProdDeployment"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      run_order = 1
      configuration = {
        CustomData = "Please approve the deployment to production"
        NotificationArn = aws_sns_topic.pipeline_approval_topic.arn  # SNS topic for approval
      }
    }
  }

  # Deploy to Prod Stage
  stage {
    name = "DeployToProd"

    action {
      name            = "DeployProd"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName        = aws_ecs_cluster.ecs_cluster.name
        ServiceName        = aws_ecs_service.prod_ecs_service.name
        FileName           = "imagedefinitions.json"
      }
    }
  }
}


resource "aws_codestarconnections_connection" "demo" {
  name          = "demo-connection"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.code_pipeline_s3_bucket
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "test-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline.json
}

# Create SNS Topic
resource "aws_sns_topic" "pipeline_approval_topic" {
  name = "pipeline-approval-topic"
}

# Create SNS Subscription for Email
resource "aws_sns_topic_subscription" "approval_email_subscription" {
  topic_arn = aws_sns_topic.pipeline_approval_topic.arn
  protocol  = "email"
  endpoint  = var.approval_email  # Email address for approval notifications
}

data "aws_iam_policy_document" "codepipeline_policy" {

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
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*"
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.demo.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
      "lambda:ListFunctions",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "opsworks:CreateDeployment",
      "opsworks:DescribeApps",
      "opsworks:DescribeCommands",
      "opsworks:DescribeDeployments",
      "opsworks:DescribeInstances",
      "opsworks:DescribeStacks",
      "opsworks:UpdateApp",
      "opsworks:UpdateStack"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudformation:CreateStack",
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "cloudformation:CreateChangeSet",
      "cloudformation:DeleteChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:SetStackPolicy",
      "cloudformation:ValidateTemplate"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "devicefarm:ListProjects",
      "devicefarm:ListDevicePools",
      "devicefarm:GetRun",
      "devicefarm:GetUpload",
      "devicefarm:CreateUpload",
      "devicefarm:ScheduleRun"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "servicecatalog:ListProvisioningArtifacts",
      "servicecatalog:CreateProvisioningArtifact",
      "servicecatalog:DescribeProvisioningArtifact",
      "servicecatalog:DeleteProvisioningArtifact",
      "servicecatalog:UpdateProduct"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudformation:ValidateTemplate"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "states:DescribeExecution",
      "states:DescribeStateMachine",
      "states:StartExecution"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "appconfig:StartDeployment",
      "appconfig:StopDeployment",
      "appconfig:GetDeployment"
    ]

    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "pass_role_permission" {
  name = "CodePipelinePassRole"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: "iam:PassRole",
        Resource: "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

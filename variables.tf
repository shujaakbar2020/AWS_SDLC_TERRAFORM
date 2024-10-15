variable "region" {
  type = string
  default = "us-east-2"
}

variable "ami" {
  type = string
  default = "ami-0d50e5e845c552faf"
}

variable "vpc_name" {
  type = string
  default = "demo"
}

variable "code_pipeline_name" {
  type = string
  default = "demo_pieline"
}

variable "code_build_name" {
  type = string
  default = "demo_code_build"
}

variable "code_build_s3_bucket" {
  type = string
  default = "codebuildbucketdemobyshuja"
}

variable "code_pipeline_s3_bucket" {
  type = string
  default = "codepipelinebucketdemobyshuja"
}

variable "github_repository_link" {
  type = string
  default = "https://github.com/shujaakbar2020/AWS_SDLC_APP.git"
}

variable "github_branch_name" {
  type = string
  default = "main"
}

variable "cloudwatch_logs_export" {
  default     = false
  description = "Whether to mark the log group to export to an S3 bucket (needs terraform-aws-log-exporter to be deployed in the account/region)"
}

variable "github_username" {
  type = string
  default = "shujaakbar2020"
}

variable "github_repository_name" {
  type = string
  default = "AWS_SDLC_APP"
}

variable "approval_email" {
  type = string
  default = "shujaakbar2020@gmail.com"
}

data "aws_caller_identity" "current" {}

# Local variable to construct the ECR URL
locals {
  docker_ecr = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-2.amazonaws.com/demo:latest"
}
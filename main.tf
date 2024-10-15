provider "aws" {
  region = "us-east-2"
}

# Retrieve the secret from AWS Secrets Manager
data "aws_secretsmanager_secret" "docker_ecr" {
  name = "docker_ecr"
}

data "aws_secretsmanager_secret_version" "docker_ecr" {
  secret_id = data.aws_secretsmanager_secret.docker_ecr.id
}

data "aws_secretsmanager_secret" "github_token" {
  name = "github_token" # Replace with your actual secret name
}

# Get the latest version of the secret value
data "aws_secretsmanager_secret_version" "github_token_version" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}
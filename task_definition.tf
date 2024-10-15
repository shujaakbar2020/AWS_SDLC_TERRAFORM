# ECS Task Definition
resource "aws_ecs_task_definition" "dev_task" {
  family                   = "ecs-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "demo"
      image     = local.docker_ecr
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.dev.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_task_definition" "stage_task" {
  family                   = "ecs-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "demo"
      image     = local.docker_ecr
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.stage.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_task_definition" "prod_task" {
  family                   = "ecs-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "demo"
      image     = local.docker_ecr
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.prod.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  lifecycle {
    ignore_changes = [task_role_arn, execution_role_arn, container_definitions]
  }
}

# Create IAM Role for ECS Task Execution
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole-policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "dev" {
  name              = "/ecs/dev"
  retention_in_days = 1
  tags = merge(
    {
      ExportToS3 = var.cloudwatch_logs_export
    }
  )
}
resource "aws_cloudwatch_log_group" "stage" {
  name              = "/ecs/stage"
  retention_in_days = 1
  tags = merge(
    {
      ExportToS3 = var.cloudwatch_logs_export
    }
  )
}
resource "aws_cloudwatch_log_group" "prod" {
  name              = "/ecs/prod"
  retention_in_days = 1
  tags = merge(
    {
      ExportToS3 = var.cloudwatch_logs_export
    }
  )
}

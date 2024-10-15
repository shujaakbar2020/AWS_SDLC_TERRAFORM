# Create ECS Service
resource "aws_ecs_service" "dev_ecs_service" {
  name            = "dev-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.dev_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.dev_task]
}

resource "aws_ecs_service" "stage_ecs_service" {
  name            = "stage-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.stage_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.stage_task]
}

resource "aws_ecs_service" "prod_ecs_service" {
  name            = "prod-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.prod_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.prod_task]
}

# resource "aws_appautoscaling_target" "ecs_scaling_target" {
#   max_capacity       = 10  # Maximum number of tasks (containers)
#   min_capacity       = 1  # Minimum number of tasks
#   resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.prod_ecs_service.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"
# }

# resource "aws_appautoscaling_policy" "scale_out_policy" {
#   name               = "scale-out"
#   service_namespace  = "ecs"
#   resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
#   policy_type        = "TargetTrackingScaling"

#   target_tracking_scaling_policy_configuration {
#     target_value       = 70.0  # Scale out if CPU utilization exceeds 70%
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     scale_out_cooldown  = 60
#     scale_in_cooldown   = 60
#   }
# }

# resource "aws_appautoscaling_policy" "scale_in_policy" {
#   name               = "scale-in"
#   service_namespace  = "ecs"
#   resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
#   policy_type        = "TargetTrackingScaling"

#   target_tracking_scaling_policy_configuration {
#     target_value       = 30.0  # Scale in if CPU utilization drops below 30%
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#     scale_out_cooldown  = 60
#     scale_in_cooldown   = 60
#   }
# }

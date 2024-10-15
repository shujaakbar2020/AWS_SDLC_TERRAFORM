# Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "demo-ecs-cluster"
}

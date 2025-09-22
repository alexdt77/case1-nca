resource "aws_cloudwatch_log_group" "prometheus" {
  name = "/ecs/prometheus"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
  memory = 512
  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  # start met default config (scrapet zichzelf), goed voor sanity check
  container_definitions = jsonencode([{
    name  = "prometheus"
    image = "prom/prometheus:latest"
    portMappings = [{ containerPort = 9090, protocol = "tcp" }]
    command = ["--storage.tsdb.retention.time=2d"]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group  = aws_cloudwatch_log_group.prometheus.name,
        awslogs-region = var.aws_region,
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "prometheus" {
  name            = "prometheus"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.app_private_a.id, aws_subnet.app_private_b.id]
    security_groups = [aws_security_group.prometheus.id]
  }
}

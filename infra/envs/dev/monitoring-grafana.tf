resource "aws_cloudwatch_log_group" "grafana" {
  name = "/ecs/grafana"
  retention_in_days = 7
}

resource "aws_lb_target_group" "grafana" {
  name     = "tg-grafana"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.app.id

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}


resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.app.arn
  port              = 3000
  protocol          = "HTTP"
  default_action { type = "forward" target_group_arn = aws_lb_target_group.grafana.arn }
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = 256
  memory = 512
  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = "grafana"
    image = "grafana/grafana:latest"
    portMappings = [{ containerPort = 3000, protocol = "tcp" }]
    environment = [
      { name = "GF_SECURITY_ADMIN_USER",     value = "admin" },
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = "changeme" }
    ]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group  = aws_cloudwatch_log_group.grafana.name,
        awslogs-region = var.aws_region,
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.app_public_a.id, aws_subnet.app_public_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.grafana.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.grafana]
}

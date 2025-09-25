# ========== SECURITY GROUPS ==========
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = aws_vpc.app.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.app.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ========== ALB ==========
resource "aws_lb" "app" {
  name               = "case1nca-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_subnet.app_public_a.id, aws_subnet.app_public_b.id]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  name        = "tg-app"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.app.id

  health_check {
    path    = "/"
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ========== ECS ==========
resource "aws_ecs_cluster" "this" {
  name = "case1-nca"
}

# ========== IAM ROLES ==========
resource "aws_iam_role" "task_execution" {
  name = "ecsTaskExecutionRole-case1nca"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "ecsTaskRole-case1nca"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

# ========== SECRETS (read) ==========
# Lookup van je secret (naam komt uit var.db_password_secret_name, bv "case1nca/db-pass")
data "aws_secretsmanager_secret" "db_pass" {
  name = var.db_password_secret_name
}

# TASK role mag (runtime) secret lezen 
data "aws_iam_policy_document" "task_secret_ro" {
  statement {
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.db_pass.arn]
  }
}

resource "aws_iam_role_policy" "task_secret_read" {
  name   = "ecsTaskSecretRead-${var.project}"
  role   = aws_iam_role.task.name
  policy = data.aws_iam_policy_document.task_secret_ro.json
}

# *** NIEUW *** Execution role moet secret kunnen ophalen voor `container_definitions.secrets`
data "aws_iam_policy_document" "exec_can_read_db_secret" {
  statement {
    sid     = "AllowReadDbPassSecret"
    effect  = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    # het basis-ARN is genoeg; de agent doet GetSecretValue op de secret
    resources = [
      data.aws_secretsmanager_secret.db_pass.arn,
      "${data.aws_secretsmanager_secret.db_pass.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "exec_read_db_secret" {
  name   = "ecsExecReadDbSecret-${var.project}"
  policy = data.aws_iam_policy_document.exec_can_read_db_secret.json
}

resource "aws_iam_role_policy_attachment" "exec_read_db_secret_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.exec_read_db_secret.arn
}

# ========== LOGS ==========
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/app"
  retention_in_days = 7
}

# ========== TASK DEFINITION ==========
resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = "${aws_ecr_repository.api.repository_url}:latest"

    portMappings = [{ containerPort = 80, protocol = "tcp" }]

    # *** AANGEPAST: echte DB host gebruiken ***
    environment = [
      { name = "DB_HOST", value = aws_db_instance.db.address },
      { name = "DB_USER", value = var.db_master_username },
      { name = "DB_NAME", value = "appdb" }
    ]

    # Secret uit Secrets Manager
    secrets = [
      { name = "DB_PASS", valueFrom = data.aws_secretsmanager_secret_version.db_pass.arn }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name,
        awslogs-region        = var.aws_region,
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  depends_on = [
    aws_iam_role_policy_attachment.exec_attach,          # standaard ECS exec policy
    aws_iam_role_policy.task_secret_read,                # task role mag (runtime) secret lezen
    aws_iam_role_policy_attachment.exec_read_db_secret_attach  # *** NIEUW: exec role mag secret lezen ***
  ]
}

# ========== SERVICE ==========
resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.app_public_a.id, aws_subnet.app_public_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.app.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}

# ========== APP AUTOSCALING ==========
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "ecs-cpu-scale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 50
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

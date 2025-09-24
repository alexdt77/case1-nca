resource "aws_security_group" "monitoring" {
  name        = "sgmonitoring"
  description = "Toegang tot Grafana (3000) en Prometheus (9090)"
  vpc_id      = var.vpc_id

  # Grafana open 
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus open
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "nca", Env = var.env }
}

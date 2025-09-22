resource "aws_security_group" "grafana" {
  name   = "sg-grafana"
  vpc_id = aws_vpc.app.id

  ingress { from_port = 3000 to_port = 3000 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] } # demo
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "prometheus" {
  name   = "sg-prometheus"
  vpc_id = aws_vpc.app.id

  # alleen verkeer vanaf grafana naar 9090
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

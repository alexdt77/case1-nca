#DB Security Group: alleen verkeer vanaf de app (ECS)
resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = aws_vpc.app.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id] # alleen app-sg
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#DB Subnet group (2 private subnets, AZ a/b) 
resource "aws_db_subnet_group" "app" {
  name       = "app-db-subnets"
  subnet_ids = [aws_subnet.app_private_a.id, aws_subnet.app_private_b.id]
}

#RDS PostgreSQL 
resource "aws_db_instance" "db" {
  identifier        = "case1nca-postgres"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  username = var.db_master_username
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false
  apply_immediately      = true
  skip_final_snapshot    = true
  deletion_protection    = false
}

# Private DNS record voor de app 
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.svc.zone_id
  name    = "db.svc.internal"
  type    = "CNAME"
  ttl     = 10
  records = [aws_db_instance.db.address]
}

output "db_endpoint" { value = aws_db_instance.db.address }
output "db_sg_id" { value = aws_security_group.db.id }

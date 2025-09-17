#DB Security group
resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = aws_vpc.data.id


  #postgresql
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.app_private_a.cidr_block,
      aws_subnet.app_private_b.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#DB Subnet group
resource "aws_db_subnet_group" "data" {
  name       = "data-subnets"
  subnet_ids = [aws_subnet.data_private_a.id, aws_subnet.data_private_b.id]
}

# --- RDS PostgreSQL (single instance, private) ---
resource "aws_db_instance" "db" {
  identifier        = "case1nca-postgres"
  engine            = var.db_engine # "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  username = var.db_master_username
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.data.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
}

# Private DNS record naar de RDS endpoint (db_instance = gebruik .address)
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.svc.zone_id
  name    = "db.svc.internal"
  type    = "CNAME"
  ttl     = 10
  records = [aws_db_instance.db.address]
}

# Outputs
output "db_endpoint" { value = aws_db_instance.db.address }
output "db_sg_id" { value = aws_security_group.db.id }

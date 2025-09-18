# VPC
resource "aws_vpc" "app" {
  cidr_block           = var.cidr_app
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "app-vpc"
  }
}

# Subnets
# Public subnet (voor ALB)
resource "aws_subnet" "app_public" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = cidrsubnet(var.cidr_app, 4, 0)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "app-public"
  }
}

# Private subnet (voor ECS + RDS)
resource "aws_subnet" "app_private" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(var.cidr_app, 4, 1)
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "app-private"
  }
}

# Internet Gateway + Routes
# IGW voor public subnet
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app.id
}

# Public route table → internet via IGW
resource "aws_route_table" "app_public" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route" "app_public_internet" {
  route_table_id         = aws_route_table.app_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_igw.id
}

resource "aws_route_table_association" "app_public_assoc" {
  subnet_id      = aws_subnet.app_public.id
  route_table_id = aws_route_table.app_public.id
}

# Private route table (geen IGW → geen direct internet)
resource "aws_route_table" "app_private" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table_association" "app_private_assoc" {
  subnet_id      = aws_subnet.app_private.id
  route_table_id = aws_route_table.app_private.id
}

# Private DNS (Route 53)
resource "aws_route53_zone" "svc" {
  name = "svc.internal"
  vpc {
    vpc_id = aws_vpc.app.id
  }

  tags = {
    Name = "private-svc-zone"
  }
}

# Record voor de database
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.svc.zone_id
  name    = "db.svc.internal"
  type    = "CNAME"
  ttl     = 10
  records = [aws_db_instance.db.address]
}

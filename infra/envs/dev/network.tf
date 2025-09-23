# VPC
resource "aws_vpc" "app" {
  cidr_block           = var.cidr_app
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "app-vpc" }
}

# Subnets (2x public, 2x private)

# Public subnets (ALB + ECS)
resource "aws_subnet" "app_public_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = cidrsubnet(var.cidr_app, 4, 0)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "app-public-a" }
}

resource "aws_subnet" "app_public_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = cidrsubnet(var.cidr_app, 4, 1)
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "app-public-b" }
}

# Private subnets (RDS)
resource "aws_subnet" "app_private_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(var.cidr_app, 4, 2)
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "app-private-a" }
}

resource "aws_subnet" "app_private_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(var.cidr_app, 4, 3)
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "app-private-b" }
}

# Internet Gateway + Routes
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "app-igw" }
}

# Public route table, internet via IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "app-public-rt" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.app_public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.app_public_b.id
  route_table_id = aws_route_table.public.id
}

# Private route table (geen internet)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "app-private-rt" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.app_private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.app_private_b.id
  route_table_id = aws_route_table.private.id
}

# Private DNS 
resource "aws_route53_zone" "svc" {
  name = "svc.internal"
  vpc { vpc_id = aws_vpc.app.id }
  tags = { Name = "svc.internal" }
}

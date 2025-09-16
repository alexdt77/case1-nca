# VPCs
resource "aws_vpc" "hub" {
  cidr_block           = var.cidr_hub
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_vpc" "app" {
  cidr_block           = var.cidr_app
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_vpc" "data" {
  cidr_block           = var.cidr_data
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Subnets (HUB)
resource "aws_subnet" "hub_public_a" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = cidrsubnet(var.cidr_hub, 4, 0)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "hub_private_a" {
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.cidr_hub, 4, 1)
  availability_zone = "${var.aws_region}a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hub.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.hub_public_a.id
  allocation_id = aws_eip.nat.id
}

# Routes (HUB)
resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id
}

resource "aws_route" "hub_public_0" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "hub_pub_assoc" {
  subnet_id      = aws_subnet.hub_public_a.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table" "hub_private" {
  vpc_id = aws_vpc.hub.id
}

resource "aws_route" "hub_private_0" {
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "hub_pri_assoc" {
  subnet_id      = aws_subnet.hub_private_a.id
  route_table_id = aws_route_table.hub_private.id
}

# App VPC
resource "aws_subnet" "app_public_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = cidrsubnet(var.cidr_app, 4, 0)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "app_private_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(var.cidr_app, 4, 1)
  availability_zone = "${var.aws_region}a"
}

# >>> TOEGEVOEGD: tweede AZ voor ALB/ECS
resource "aws_subnet" "app_public_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = cidrsubnet(var.cidr_app, 4, 2)
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "app_private_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(var.cidr_app, 4, 3)
  availability_zone = "${var.aws_region}b"
}

# IGW + routes voor APP (nodig voor internet-facing ALB)
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "app_public" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "app_private" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route" "app_public_0" {
  route_table_id         = aws_route_table.app_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.app_igw.id
}

resource "aws_route_table_association" "app_pub_assoc" {
  route_table_id = aws_route_table.app_public.id
  subnet_id      = aws_subnet.app_public_a.id
}

resource "aws_route_table_association" "app_pri_assoc" {
  route_table_id = aws_route_table.app_private.id
  subnet_id      = aws_subnet.app_private_a.id
}

# >>> TOEGEVOEGD: route-table associations voor AZ b
resource "aws_route_table_association" "app_pub_assoc_b" {
  route_table_id = aws_route_table.app_public.id
  subnet_id      = aws_subnet.app_public_b.id
}

resource "aws_route_table_association" "app_pri_assoc_b" {
  route_table_id = aws_route_table.app_private.id
  subnet_id      = aws_subnet.app_private_b.id
}
# <<<

# Data VPC
resource "aws_subnet" "data_private_a" {
  vpc_id            = aws_vpc.data.id
  cidr_block        = cidrsubnet(var.cidr_data, 4, 0)
  availability_zone = "${var.aws_region}a"
}

resource "aws_route_table" "data_private" {
  vpc_id = aws_vpc.data.id
}

resource "aws_route_table_association" "data_pri_assoc" {
  route_table_id = aws_route_table.data_private.id
  subnet_id      = aws_subnet.data_private_a.id
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description = "case1-nca"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att_hub" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.hub.id
  subnet_ids         = [aws_subnet.hub_private_a.id]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att_app" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.app.id
  subnet_ids         = [aws_subnet.app_private_a.id]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "att_data" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.data.id
  subnet_ids         = [aws_subnet.data_private_a.id]
}

# Spokes
resource "aws_route" "app_default_to_tgw" {
  route_table_id         = aws_route_table.app_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "data_default_to_tgw" {
  route_table_id         = aws_route_table.data_private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Private DNS zone
resource "aws_route53_zone" "svc" {
  name = "svc.internal"
  vpc { vpc_id = aws_vpc.app.id }
  vpc { vpc_id = aws_vpc.data.id }
}

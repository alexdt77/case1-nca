data "aws_ami" "al2_grafana" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "grafana" {
  ami                         = data.aws_ami.al2_grafana.id
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = <<EOF
#!/bin/bash
set -eux
yum update -y
amazon-linux-extras install docker -y || yum install -y docker
systemctl enable docker
systemctl start docker

docker run -d --name grafana --restart unless-stopped \
  -p 3000:3000 grafana/grafana:latest
EOF

  tags = {
    Name    = "grafana-${var.env}"
    Project = "nca"
  }
}

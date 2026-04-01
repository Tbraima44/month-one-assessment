terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # or your specific version
    }
  }
}


provider "aws" {
  region = var.region
}

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 1. VPC
resource "aws_vpc" "techcorp" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techcorp-vpc"
  }
}

# 2. Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.techcorp.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "techcorp-public-subnet-1" }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.techcorp.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "techcorp-public-subnet-2" }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.techcorp.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = { Name = "techcorp-private-subnet-1" }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.techcorp.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = { Name = "techcorp-private-subnet-2" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp.id

  tags = { Name = "techcorp-igw" }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat1" {
}
resource "aws_eip" "nat2" {
}

# NAT Gateways (one per AZ for HA)
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public1.id

  tags = { Name = "techcorp-nat-1" }
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public2.id

  tags = { Name = "techcorp-nat-2" }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.techcorp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "techcorp-public-rt" }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.techcorp.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }

  tags = { Name = "techcorp-private-rt-1" }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.techcorp.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat2.id
  }

  tags = { Name = "techcorp-private-rt-2" }
}

# Route Table Associations
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

# 4. Security Groups
resource "aws_security_group" "bastion" {
  name        = "techcorp-bastion-sg"
  description = "Bastion Security Group"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-bastion-sg" }
}

resource "aws_security_group" "web" {
  name        = "techcorp-web-sg"
  description = "Web Servers Security Group"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }


  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-web-sg" }
}

resource "aws_security_group" "db" {
  name        = "techcorp-db-sg"
  description = "Database Security Group"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-db-sg" }
}

resource "aws_security_group" "alb" {
  name        = "techcorp-alb-sg"
  description = "Application Load Balancer SG"
  vpc_id      = aws_vpc.techcorp.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-alb-sg" }
}

# 5. EC2 Instances

# Bastion Host (Public)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux2.id
  instance_type               = var.instance_type_bastion
  subnet_id                   = aws_subnet.public1.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name
  user_data_replace_on_change = true

  tags = { Name = "techcorp-bastion" }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
}

# Web Servers (Private)
resource "aws_instance" "web1" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = file("user_data/web_server_setup.sh")
  key_name               = var.key_pair_name
  user_data_replace_on_change = true

  tags = { Name = "techcorp-web-1" }
}

resource "aws_instance" "web2" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = file("user_data/web_server_setup.sh")
  key_name               = var.key_pair_name
  user_data_replace_on_change = true

  tags = { Name = "techcorp-web-2" }
}

# Database Server (Private)
resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.db.id]
  user_data              = file("user_data/db_server_setup.sh")
  key_name               = var.key_pair_name
  user_data_replace_on_change = true

  tags = { Name = "techcorp-db" }
}

# 6. Application Load Balancer
resource "aws_lb" "techcorp" {
  name               = "techcorp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = { Name = "techcorp-alb" }
}

resource "aws_lb_target_group" "web" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp.id

  health_check {
    path                = "/health"          # ← Much more reliable
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"              # Explicit success code
  }

  tags = { Name = "techcorp-web-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.techcorp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group_attachment" "web1" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web2" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web2.id
  port             = 80
}
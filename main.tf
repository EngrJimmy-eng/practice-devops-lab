

provider "aws" {
  region = var.region
}

# --- VPC ---
resource "aws_vpc" "practice_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "PracticeVPC"
    Environment = "dev"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "practice_igw" {
  vpc_id = aws_vpc.practice_vpc.id

  tags = {
    Name        = "Practice-IGW"
    Environment = "dev"
  }
}

# --- Public Subnet ---
resource "aws_subnet" "practice_public_subnet" {
  vpc_id                  = aws_vpc.practice_vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "Practice-Public-Subnet"
    Environment = "dev"
  }
}

# --- Public Route Table ---
resource "aws_route_table" "practice_public_rt" {
  vpc_id = aws_vpc.practice_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.practice_igw.id
  }

  tags = {
    Name        = "Practice-Public-RT"
    Environment = "dev"
  }
}

# --- Associate Public Subnet with Route Table ---
resource "aws_route_table_association" "practice_public_assoc" {
  subnet_id      = aws_subnet.practice_public_subnet.id
  route_table_id = aws_route_table.practice_public_rt.id
}

# --- Security Group for Practice Instance ---
resource "aws_security_group" "practice_sg" {
  name        = "practice-sg"
  description = "Allow SSH, HTTP, and Docker testing ports"
  vpc_id      = aws_vpc.practice_vpc.id

  ingress {
    description = "SSH/SSM"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Docker Test"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Optional HTTP port 80"
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

  tags = {
    Name = "Practice-SG"
  }
}

# --- EC2 Practice Instance ---
resource "aws_instance" "practice_ec2" {
  ami                    = "ami-0c02fb55956c7d316" # Ubuntu 22.04 in eu-west-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.practice_public_subnet.id
  security_groups        = [aws_security_group.practice_sg.name]
  associate_public_ip_address = true

  tags = {
    Name        = "Practice-EC2"
    Environment = "dev"
  }

  # Install Docker automatically
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF
}

# --- Data source for AZs ---
data "aws_availability_zones" "available" {
  state = "available"
}

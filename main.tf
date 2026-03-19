provider "aws" {
  region = var.region
}

# --- Get Available AZs ---
data "aws_availability_zones" "available" {
  state = "available"
}

# --- Get Latest Ubuntu AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
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

# --- Route Table Association ---
resource "aws_route_table_association" "practice_public_assoc" {
  subnet_id      = aws_subnet.practice_public_subnet.id
  route_table_id = aws_route_table.practice_public_rt.id
}

# --- Security Group ---
resource "aws_security_group" "practice_sg" {
  name        = "practice-sg"
  description = "Allow SSH, HTTP, and Docker ports"
  vpc_id      = aws_vpc.practice_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Docker App Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

# --- EC2 Instance ---
resource "aws_instance" "practice_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.practice_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.practice_sg.id]
  associate_public_ip_address = true

  tags = {
    Name        = "Practice-EC2"
    Environment = "dev"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
# Run Nginx container automatically
              docker run -d -p 8080:80 --name nginx-server nginx
              EOF
}

data "aws_iam_role" "ssm_role" {
  name = "EC2-SSM-Role"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = data.aws_iam_role.ssm_role.name
}


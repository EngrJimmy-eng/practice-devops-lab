# --- AWS Region ---
variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-1"
}

# --- Availability Zones ---
variable "availability_zones" {
  description = "List of Availability Zones for subnets"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]  # Adjust to your region
}

# --- EC2 Instance Type ---
variable "instance_type" {
  description = "EC2 instance type for the practice server"
  type        = string
  default     = "t3.micro"
}

# --- EC2 AMI ---
variable "ami" {
  description = "Ubuntu AMI for the EC2 instance"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Ubuntu 22.04 in eu-west-1
}

# --- VPC CIDR ---
variable "vpc_cidr" {
  description = "CIDR block for the practice VPC"
  type        = string
  default     = "10.10.0.0/16"
}

# --- Public Subnet CIDR ---
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.10.1.0/24"
}

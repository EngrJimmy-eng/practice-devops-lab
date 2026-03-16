# --- Public IP of the practice EC2 instance ---
output "practice_ec2_public_ip" {
  description = "The public IP address of the practice EC2 instance"
  value       = aws_instance.practice_ec2.public_ip
}

# --- Private IP of the EC2 instance (optional) ---
output "practice_ec2_private_ip" {
  description = "The private IP address of the practice EC2 instance"
  value       = aws_instance.practice_ec2.private_ip
}

# --- Security Group ID (optional) ---
output "practice_sg_id" {
  description = "Security group ID attached to the practice EC2 instance"
  value       = aws_security_group.practice_sg.id
}

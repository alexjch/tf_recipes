output "public_dns" {
  description = "DNS name for the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "public_ip" {
  description = "Public IP address for the EC2 instance"
  value       = aws_instance.this.public_ip
}

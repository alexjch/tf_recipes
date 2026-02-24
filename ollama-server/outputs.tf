output "public_dns" {
  description = "DNS name for EC2 instance"
  value       = aws_instance.ollama_server.public_dns
}

output "public_ip" {
  description = "Public IP address for EC2 instance"
  value       = aws_instance.ollama_server.public_ip
}

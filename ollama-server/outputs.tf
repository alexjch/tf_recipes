output "public_dns" {
  description = "DNS name for EC2 instance"
  value       = module.server.public_dns
}

output "public_ip" {
  description = "Public IP address for EC2 instance"
  value       = module.server.public_ip
}

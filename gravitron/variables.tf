variable "image_id" {
  description = "AMI for ARM64 in us-west-2"
  default     = "ami-0aed0cf56d6c464bc"
}

variable "vm_type" {
  description = "AWS Graviton instance type"
  default     = "t4g.medium"
}

variable "key_name" {
  description = "Name for the imported AWS key pair"
  default     = "aws_key"
}

variable "username" {
  description = "Username to create through cloud-init"
  default     = "gravitron"
}

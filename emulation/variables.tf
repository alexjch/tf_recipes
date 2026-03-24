variable "image_id" {
  description = "AMI Fedora 41 Cloud Image - x86_64"
  default     = "ami-0ea0f0aecf4b692ea"
}

variable "vm_type" {
  description = "AWS instance type"
  default     = "t3.large"
}

variable "key_name" {
  description = "Name for the imported AWS key pair"
  default     = "aws_key"
}

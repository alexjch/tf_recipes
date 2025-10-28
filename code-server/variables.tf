variable "username" {
  description = "Username for the user that will own coder service"
  default     = "coderadmin"
}

variable "image_id" {
  description = "AMI to use for code-server deployment"
  default     = "ami-0a208b2fa6dfc6a92"
}

variable "vm_type" {
  description = "AWS Instance type"
  default     = "t2.micro"
}

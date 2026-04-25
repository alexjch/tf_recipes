variable "name" {
  description = "Name for the EC2 instance and associated resources"
  type        = string
}

variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name for the imported AWS key pair"
  type        = string
}

variable "public_key" {
  description = "SSH public key content"
  type        = string
}

variable "user_data" {
  description = "User data (cloud-init) for the instance"
  type        = string
  default     = null
}

variable "volume_size" {
  description = "EBS root volume size in GB"
  type        = number
  default     = 16
}

variable "volume_type" {
  description = "EBS root volume type"
  type        = string
  default     = "gp3"
}

variable "cpu_options" {
  description = "Optional CPU options block. Set threads_per_core and/or nested_virtualization as needed."
  type = object({
    threads_per_core      = optional(number)
    nested_virtualization = optional(string)
  })
  default = null
}

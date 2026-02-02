variable "username" {
  description = "Username for the user that will own coder service"
  default     = "admin"
}

variable "image_id" {
  description = "AMI Fedora 41 Cloud Image - x86_64" # us-west-2 aka Oregon
  default     = "ami-0ea0f0aecf4b692ea"
}

# vCPUs: 16
# Memory: 32 GiB
# Processor: Intel Xeon Scalable (3rd Gen, Intel Ice Lake) with AVX-512 support
# Storage: EBS-only (no instance store)
# Networking: Up to 12.5 Gbps (baseline depends on AZ)
# Use case: CPU-bound workloads like high-performance web servers, batch processing, and CPU inference.
variable "vm_type" {
  description = "AWS Instance type"
  default     = "c6i.4xlarge"
}

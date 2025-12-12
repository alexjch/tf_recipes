variable "lambda_function_name" {
    description = "Collector endpoint"
    type        = string
    default     = "data-collector"
}

variable "s3_bucket_name" {
    description = "Collected data"
    type        = string
    default     = "storage-3595aa82-8cfc-4c41-a2f3-53a4c51e5bd7"
}

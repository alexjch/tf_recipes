variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "us-west-2"
}

variable "lambda_function_name" {
    description = "Collector endpoint"
    type        = string
    default     = "data-collector"
}

variable "s3_bucket_name" {
    description = "Collected data"
    type        = string
    default     = "lambda-store-3595aa82-8cfc-4c41-a2f3-53a4c51e5bd7"
}

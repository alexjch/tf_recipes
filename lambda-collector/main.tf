# Lambda-based data collector with S3 storage
# 
# Architecture Overview:
# This module creates a serverless data collector using AWS Lambda with S3 storage backend.
# The Lambda function is exposed via a public function URL and stores collected data in S3.
#
# Dependencies (creation order):
# 1. S3 bucket (data_bucket) - storage for collected data
# 2. IAM role (lambda_role) - Lambda execution identity
# 3. IAM policies (lambda_s3_policy, lambda_basic_execution) - permissions for S3 access and CloudWatch Logs
# 4. Lambda function (data_collector) - depends on role and S3 bucket for environment variables
# 5. Lambda function URL (data_collector_endpoint) - public endpoint to invoke the Lambda function

# --------------------------------------------------
# S3 Storage Configuration
# --------------------------------------------------

# S3 bucket for storing collected data
# Note: force_destroy = true allows bucket deletion even when containing objects (use with caution)
resource "aws_s3_bucket" "data_bucket" {
    bucket        = var.s3_bucket_name
    force_destroy = true
}

# Block all public access to the S3 bucket
# Ensures collected data is not publicly accessible
resource "aws_s3_bucket_public_access_block" "data_bucket" {
    bucket = aws_s3_bucket.data_bucket.id

    block_public_acls       = true  # Block public ACLs on this bucket
    block_public_policy     = true  # Block public bucket policies
    ignore_public_acls      = true  # Ignore existing public ACLs
    restrict_public_buckets = true  # Restrict public bucket policies
}

# Enable versioning for data recovery and audit trail
# Allows restoration of deleted or overwritten objects
resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
    bucket = aws_s3_bucket.data_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

# --------------------------------------------------
# IAM Configuration
# --------------------------------------------------

# IAM role for Lambda function execution
# Allows Lambda service to assume this role and execute the function
resource "aws_iam_role" "lambda_role" {
    name = "${var.lambda_function_name}-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

# IAM policy granting Lambda permission to write to and read from S3
# Scoped to objects within the data bucket only
resource "aws_iam_role_policy" "lambda_s3_policy" {
    name = "${var.lambda_function_name}-s3-policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",  # Write objects to S3
                    "s3:GetObject"   # Read objects from S3
                ]
                Resource = "${aws_s3_bucket.data_bucket.arn}/*"
            }
        ]
    })
}

# Attach AWS managed policy for basic Lambda execution
# Provides permissions to write logs to CloudWatch Logs
# Required for Lambda function monitoring and debugging
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --------------------------------------------------
# Lambda Function Configuration
# --------------------------------------------------

# Lambda function for data collection
# Prerequisites:
# - Deployment package must exist at ${path.module}/function/lambda_handler.zip
# - Package should contain a lambda.handler function as the entry point
# - Runtime: Python 3.14
resource "aws_lambda_function" "data_collector" {
    filename      = "${path.module}/function/lambda_handler.zip"
    function_name = var.lambda_function_name
    role          = aws_iam_role.lambda_role.arn
    handler       = "lambda.handler" # Format: <filename>.<function_name>
    runtime       = "python3.14"

    # Triggers function update when deployment package changes
    source_code_hash = filebase64sha256("${path.module}/function/lambda_handler.zip")

    # Environment variables available to the Lambda function
    environment {
        variables = {
            S3_BUCKET = aws_s3_bucket.data_bucket.id  # Target bucket for data storage
        }
    }
}

# --------------------------------------------------
# Lambda Function URL (Public Endpoint)
# --------------------------------------------------

# Creates a public HTTPS endpoint for the Lambda function
# WARNING: authorization_type = "NONE" means the endpoint is publicly accessible
# Consider implementing authentication for production use
resource "aws_lambda_function_url" "data_collector_endpoint" {
  function_name      = aws_lambda_function.data_collector.function_name
  authorization_type = "NONE"  # No authentication required (public access)
}

# Lambda-based data collector with S3 storage and bearer token authentication
#
# Architecture Overview:
# This module creates a serverless data collector using AWS Lambda with S3 storage backend.
# The Lambda function is exposed via a public function URL with bearer token authentication
# stored in AWS Secrets Manager, and stores collected data in S3.
#
# Dependencies (creation order):
# 1. S3 bucket (data_bucket) - storage for collected data
# 2. IAM role (lambda_role) - Lambda execution identity
# 3. Random string (secret) - generates bearer token value
# 4. Secrets Manager secret (bearer_token) - stores authentication token
# 5. Secrets Manager secret version (bearer_token_version) - contains token value
# 6. IAM policies (lambda_s3_policy, lambda_secretsmanager_policy, lambda_basic_execution) 
#    - permissions for S3 access, Secrets Manager access, and CloudWatch Logs
# 7. Lambda function (data_collector) - depends on role, S3 bucket, and secret for environment variables
# 8. Lambda function URL (data_collector_endpoint) - public endpoint to invoke the Lambda function

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

# IAM policy granting Lambda permission to read bearer token from Secrets Manager
# Allows the Lambda function to retrieve the authentication token for validation
resource "aws_iam_role_policy" "lambda_secretsmanager_policy" {
    name = "${var.lambda_function_name}-secretsmanager-policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "secretsmanager:GetSecretValue"  # Read secret value
                ]
                Resource = aws_secretsmanager_secret.bearer_token.arn
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
# Authentication Configuration
# --------------------------------------------------

# Generate a random bearer token for Lambda function authentication
# This token should be included in the Authorization header when calling the function URL
resource "random_string" "secret" {
  length  = 24          # Length of the secret string
  upper   = true        # Include uppercase letters
  lower   = true        # Include lowercase letters
  numeric = true        # Include numbers
  special = false       # Exclude special characters for simplicity
}

# AWS Secrets Manager secret to store the bearer token
# Note: recovery_window_in_days = 0 allows immediate deletion (use with caution)
# lifecycle.ignore_changes = all prevents accidental token rotation via Terraform
resource "aws_secretsmanager_secret" "bearer_token" {
    name = "bearer_token_name"
    description = "Authentication token for calling lambda function"
    recovery_window_in_days = 0  # Immediate deletion without recovery window
    lifecycle {
        prevent_destroy = false  # Allow destruction via terraform destroy
        ignore_changes  = all    # Ignore changes to prevent unintended updates
    }
}

# Store the generated bearer token value in Secrets Manager
# The Lambda function reads this value to validate incoming requests
resource "aws_secretsmanager_secret_version" "bearer_token_version" {
    secret_id = aws_secretsmanager_secret.bearer_token.id
    secret_string = random_string.secret.result
}

# --------------------------------------------------
# Lambda Function Configuration
# --------------------------------------------------

# Lambda function for data collection
# Prerequisites:
# - Deployment package must exist at ${path.module}/function/lambda_handler.zip
# - Package should contain a lambda.handler function as the entry point
# - Runtime: Python 3.14
# - Function validates bearer token from Authorization header against Secrets Manager
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
            SECRET_NAME = aws_secretsmanager_secret.bearer_token.name  # Secret name for token validation
        }
    }
}

# --------------------------------------------------
# Lambda Function URL (Public Endpoint)
# --------------------------------------------------

# Creates a public HTTPS endpoint for the Lambda function
# WARNING: authorization_type = "NONE" means AWS does not enforce authentication
# Application-level authentication via bearer token is implemented in the Lambda function code
resource "aws_lambda_function_url" "data_collector_endpoint" {
  function_name      = aws_lambda_function.data_collector.function_name
  authorization_type = "NONE"  # No AWS-level authentication (authentication handled in function code)
}

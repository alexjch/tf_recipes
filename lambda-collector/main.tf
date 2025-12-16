# Lambda-based data collector with S3 storage and API Gateway
#
# Architecture:
# - Lambda function receives data via API Gateway
# - Data is stored in versioned S3 bucket
# - CloudWatch Logs enabled for monitoring
#
# Resource creation order:
# 1. S3 bucket (data_bucket) - storage for collected data
# 2. IAM role (lambda_role) - Lambda execution identity
# 3. IAM policies - permissions for S3 access and CloudWatch Logs
# 4. Lambda function (data_collector) - main application logic
# 5. API Gateway - public HTTP endpoint

# ============================================================================
# S3 Storage
# ============================================================================

# Primary data storage bucket
resource "aws_s3_bucket" "data_bucket" {
    bucket        = var.s3_bucket_name
    force_destroy = true # WARNING: Deletes all objects when bucket is destroyed
}

# Enforce private bucket access
resource "aws_s3_bucket_public_access_block" "data_bucket" {
    bucket = aws_s3_bucket.data_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# Enable versioning for data recovery and audit trail
resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
    bucket = aws_s3_bucket.data_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

# ============================================================================
# IAM Role and Permissions
# ============================================================================

# Lambda execution role
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

# Grant Lambda permission to read and write objects in the data bucket
resource "aws_iam_role_policy" "lambda_s3_policy" {
    name = "${var.lambda_function_name}-s3-policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:GetObject"
                ]
                Resource = "${aws_s3_bucket.data_bucket.arn}/*"
            }
        ]
    })
}

# Attach AWS managed policy for CloudWatch Logs access
# Provides permissions to create log groups/streams and write log events
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ============================================================================
# Lambda Function
# ============================================================================

# Data collector function
resource "aws_lambda_function" "data_collector" {
    filename      = "${path.module}/function/lambda_handler.zip"
    function_name = var.lambda_function_name
    role          = aws_iam_role.lambda_role.arn
    handler       = "lambda.handler" # File: lambda.py, Function: handler
    runtime       = "python3.11"

    # Trigger redeployment when function code changes
    source_code_hash = filebase64sha256("${path.module}/function/lambda_handler.zip")

    environment {
        variables = {
            S3_BUCKET = aws_s3_bucket.data_bucket.id
        }
    }
}

# ============================================================================
# API Gateway Configuration
# ============================================================================

# REST API definition
resource "aws_api_gateway_rest_api" "data_collector_api" {
    name        = "${var.lambda_function_name}-api"
    description = "API Gateway for data collector Lambda function"
}

# Handle requests to root path (/)
# Reference: https://aws.amazon.com/blogs/developer/handling-arbitrary-http-requests-in-amazon-api-gateway/
resource "aws_api_gateway_method" "root" {
    rest_api_id   = aws_api_gateway_rest_api.data_collector_api.id
    resource_id   = aws_api_gateway_rest_api.data_collector_api.root_resource_id
    http_method   = "ANY" # Accept all HTTP methods (GET, POST, PUT, etc.)
    authorization = "NONE"
}

# Integrate root path with Lambda
resource "aws_api_gateway_integration" "lambda_root" {
    rest_api_id = aws_api_gateway_rest_api.data_collector_api.id
    resource_id = aws_api_gateway_rest_api.data_collector_api.root_resource_id
    http_method = aws_api_gateway_method.root.http_method

    integration_http_method = "POST" # API Gateway always invokes Lambda via POST
    type                    = "AWS_PROXY" # Pass request directly to Lambda
    uri                     = aws_lambda_function.data_collector.invoke_arn
}

# Proxy resource to catch all paths (e.g., /users, /data/items)
resource "aws_api_gateway_resource" "proxy" {
    rest_api_id = aws_api_gateway_rest_api.data_collector_api.id
    parent_id   = aws_api_gateway_rest_api.data_collector_api.root_resource_id
    path_part   = "{proxy+}" # Greedy path variable
}

# Handle requests to any sub-path
resource "aws_api_gateway_method" "proxy" {
    rest_api_id   = aws_api_gateway_rest_api.data_collector_api.id
    resource_id   = aws_api_gateway_resource.proxy.id
    http_method   = "ANY"
    authorization = "NONE"
}

# Integrate proxy paths with Lambda
resource "aws_api_gateway_integration" "lambda_proxy" {
    rest_api_id = aws_api_gateway_rest_api.data_collector_api.id
    resource_id = aws_api_gateway_resource.proxy.id
    http_method = aws_api_gateway_method.proxy.http_method

    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.data_collector.invoke_arn
}

# Grant API Gateway permission to invoke Lambda function
resource "aws_lambda_permission" "api_gateway" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.data_collector.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.data_collector_api.execution_arn}/*/*"
}

# ============================================================================
# API Gateway Deployment
# ============================================================================

# Create deployment snapshot of API configuration
resource "aws_api_gateway_deployment" "data_collector_prod_api" {
    depends_on = [
        aws_api_gateway_integration.lambda_root,
        aws_api_gateway_integration.lambda_proxy
    ]

    rest_api_id = aws_api_gateway_rest_api.data_collector_api.id

    lifecycle {
        create_before_destroy = true # Prevent downtime during updates
    }
}

# Production stage (accessible via URL)
resource "aws_api_gateway_stage" "prod" {
    deployment_id = aws_api_gateway_deployment.data_collector_prod_api.id
    rest_api_id   = aws_api_gateway_rest_api.data_collector_api.id
    stage_name    = "prod"
}

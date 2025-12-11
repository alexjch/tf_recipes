# S3 Bucket for storing data
resource "aws_s3_bucket" "data_bucket" {
    bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
    bucket = aws_s3_bucket.data_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

# IAM Role for Lambda
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

# IAM Policy for Lambda to write to S3
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

# Attach basic Lambda execution policy
#   AWSLambdaBasicExecutionRole, provides write permissions to CloudWatch Logs, a basic
#   condition for execution of the function
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "data_collector" {
    filename      = "${path.module}/function/lambda_handler.zip"
    function_name = var.lambda_function_name
    role          = aws_iam_role.lambda_role.arn
    handler       = "lambda.handler"
    runtime       = "python3.11"

    source_code_hash = filebase64sha256("${path.module}/function/lambda_handler.zip")

    environment {
        variables = {
            S3_BUCKET = aws_s3_bucket.data_bucket.id
        }
    }
}

# Lambda function URL
resource "aws_lambda_function_url" "data_collector_endpoint" {
  function_name      = var.lambda_function_name
  authorization_type = "NONE"
}
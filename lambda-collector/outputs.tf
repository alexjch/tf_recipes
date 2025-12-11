output "lambda_function_arn" {
    value = aws_lambda_function.data_collector.arn
}

output "s3_bucket_name" {
    value = aws_s3_bucket.data_bucket.id
}

output "data_collector_endpoint" {
    value = aws_lambda_function_url.data_collector_endpoint
}

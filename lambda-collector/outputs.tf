output "lambda_function_arn" {
    value = aws_lambda_function.data_collector.arn
}

output "s3_bucket_name" {
    value = aws_s3_bucket.data_bucket.id
}

output "api_gateway_url" {
    value = "${aws_api_gateway_stage.prod.invoke_url}"
}

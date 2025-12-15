# Lambda Collector

Generic collector using AWS lambda and S3 for storage

## Overview

This project provides infrastructure and code for deploying Lambda-based data collection pipelines.

## Features

- Serverless data collection
- AWS Lambda integration
- Scalable architecture

## Getting Started

### Prerequisites

- AWS Account
- Terraform

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd lambda-collector

# Install dependencies
# Add specific installation steps here
```

## Usage

Deploy the infrastructure using Terraform:

```bash
terraform init
terraform validate
terraform apply


...
Outputs:

api_gateway_url = "https://yzw9o76fxb.execute-api.us-west-2.amazonaws.com/prod"
lambda_function_arn = "arn:aws:lambda:us-west-2:713881820835:function:data-collector"
s3_bucket_name = "storage-3595aa82-8cfc-4c41-a2f3-53a4c51e5bd7"
```

**Note:** ```api_gateway_url``` this endpoint is neccesary for next steps

## Test collector with ```curl``` and ```aws s3```

```bash
curl -vv -XPOST $(tf output -raw api_gateway_url) -d '{"payload":"hello world!"}'

```

## TODO:
- Secure endpoint: API Gateway offers lots of great options. But fear of vendor lock in makes me opt for mutual TLS authentication. (authz is out of scope).

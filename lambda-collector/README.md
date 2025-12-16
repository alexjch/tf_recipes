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

data_collector_endpoint = "https://asjpvdj4wt4b4c4amde4btnwde0llqrh.lambda-url.us-west-2.on.aws/"
lambda_function_arn = "arn:aws:lambda:us-west-2:713881820835:function:data-collector"
s3_bucket_name = "storage-3595aa82-8cfc-4c41-a2f3-53a4c51e5bd7"
```

**Note:** ```data_collector_endpoint``` this endpoint is neccesary for next steps

## Test collector with ```curl``` and ```aws s3```

```bash
# Send an object. Make a copy of the filename
curl -X POST $(terraform output -raw data_collector_endpoint) -d '{"payload": "Hello World!!"}'
{"message": "Data saved successfully", "filename": "20251216/1765915795-18341ebf-a294-407f-a8cd-506af4ace008"}

# Check that is saved in s3, Using the filename printed in the HTTP response
aws s3 cp s3://$(terraform output -raw s3_bucket_name)/20251216/1765915795-18341ebf-a294-407f-a8cd-506af4ace008 -
{"payload": "Hello World!!"}
```

## TODO:
- Secure endpoint.

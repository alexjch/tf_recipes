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

data_collector_endpoint = {
  "authorization_type" = "NONE"
  "cors" = tolist([])
  "function_arn" = "arn:aws:lambda:us-west-2:713881820835:function:data-collector"
  "function_name" = "data-collector"
  "function_url" = "https://xiuiqeea2fxypgtvyr7mnozyuq0wxrwb.lambda-url.us-west-2.on.aws/"
  "id" = "data-collector"
  "invoke_mode" = "BUFFERED"
  "qualifier" = ""
  "region" = "us-west-2"
  "timeouts" = null /* object */
  "url_id" = "xiuiqeea2fxypgtvyr7mnozyuq0wxrwb"
}

```

**Note:** ```data_collector_endpoint.function_url``` this endpoint is neccesary for next steps

## Test collector with ```curl``` and ```aws s3```

```bash
curl -vv -XPOST "https://xiuiqeea2fxypgtvyr7mnozyuq0wxrwb.lambda-url.us-west-2.on.aws/" -d '{"payload":"hello world!"}'

```

## TODO:
- Secure endpoint: API Gateway offers lots of great options. But fear of vendor lock in makes me opt for mutual TLS authentication. (authz is out of scope).

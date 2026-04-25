# Gravitron EC2 Deployment

Simple Terraform deployment for a single AWS Graviton EC2 instance in `us-west-2`.

## Notes

- Uses AWS region `us-west-2`.
- Default instance type is `t4g.medium` (Graviton/ARM64).
- By default, AMI is resolved from AWS SSM Parameter Store for Amazon Linux 2023 ARM64.
- You can override AMI by setting `image_id`.
- Place your public key at `keys/aws_key.pub` before apply.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

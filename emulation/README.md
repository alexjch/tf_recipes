# Emulation EC2 Deployment

Simple Terraform deployment for a single EC2 instance.

## Notes

- This deployment creates infrastructure only.
- No software provisioning or `user_data` is configured.
- Place your public key at `keys/aws_key.pub` before apply.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

# Ollama Server on AWS EC2

This Terraform recipe deploys a production-ready Ollama server on AWS EC2, optimized for CPU-only inference using Intel Xeon processors. The deployment uses Fedora Cloud as the base OS and includes automated installation and configuration of Ollama.

## Project Overview

**What it does:**
- Provisions an AWS EC2 instance (default: `c6i.4xlarge` with 16 vCPUs, 32 GiB RAM)
- Uses Fedora 41 Cloud Image optimized for cloud deployments
- Configures security group allowing SSH access only (no public HTTP/HTTPS)
- Automatically sets up Ollama service via cloud-init
- Optimizes Ollama for Intel Xeon CPUs with AVX-512 support

**Key Components:**
- **main.tf**: Defines EC2 instance, security groups, and key pair resources
- **locals.tf**: Processes cloud-init template with user configuration
- **scripts/server-conf.yaml**: Cloud-init configuration that installs and configures Ollama (CPU-only, Intel Xeon optimized)

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- SSH key pair for instance access

## Setup Instructions

### 1. Prepare SSH Keys

Generate an ED25519 SSH key pair:

```bash
ssh-keygen -t ed25519 -f keys/aws_key
```

This creates:
- `keys/aws_key` - Private key (keep secure)
- `keys/aws_key.pub` - Public key (deployed to EC2)

### 2. Configure Variables (Optional)

Review and customize variables.tf:

```bash
# Default username for admin access
username = "admin"

# AWS region AMI for Fedora 41 (us-west-2)
image_id = "ami-0ea0f0aecf4b692ea"

# Instance type - c6i.4xlarge provides:
# - 16 vCPUs (Intel Xeon 3rd Gen Ice Lake)
# - 32 GiB Memory
# - AVX-512 instruction support
# - Up to 12.5 Gbps networking
vm_type = "c6i.4xlarge"
```

### 3. Deploy Infrastructure

Initialize and apply Terraform configuration:

```bash
terraform init
terraform validate
terraform apply
```

To use a different instance type:

```bash
terraform apply -var="vm_type=c6i.2xlarge"
```

### 4. Access the Instance

After deployment completes, retrieve connection details:

```bash
terraform output public_ip
terraform output public_dns
```

Connect via SSH:

```bash
ssh -i keys/aws_key admin@$(terraform output -raw public_ip)
```

### 5. Verify Ollama Installation

Cloud-init automatically installs and configures Ollama. Check the service status:

```bash
sudo systemctl status ollama
```

Test Ollama is responding:

```bash
curl http://localhost:11434/api/version
```

## Using Ollama

### Pull and Run Models

```bash
# Pull a model
ollama pull llama3.2

# Run the model
ollama run llama3.2
```

### Access from Remote Machine

Ollama listens on `127.0.0.1:11434` by default. To access remotely, use SSH tunneling:

```bash
ssh -i keys/aws_key -L 11434:localhost:11434 admin@<instance-ip>
```

Then on your local machine:

```bash
curl http://localhost:11434/api/version
ollama list
```

## Instance Specifications

The default `c6i.4xlarge` instance is optimized for CPU inference:
- **Processor**: Intel Xeon Scalable (3rd Gen Ice Lake) with AVX-512
- **vCPUs**: 16 cores for parallel processing
- **Memory**: 32 GiB for loading multiple models
- **Storage**: 20 GiB EBS GP2 volume
- **Network**: Up to 12.5 Gbps bandwidth

Ollama is configured with:
- `OLLAMA_NUM_THREADS`: Auto-detected based on CPU cores
- `OLLAMA_NUM_PARALLEL=2`: Handle 2 concurrent requests
- `OLLAMA_MAX_LOADED_MODELS=2`: Keep 2 models in memory

## Security Considerations

- **Network Access**: Only port 22 (SSH) is exposed publicly
- **Ollama Access**: Bound to localhost only - use SSH tunneling for remote access
- **Key-based Auth**: Password authentication disabled, SSH key required
- **Sudo Access**: Admin user has passwordless sudo for system management

## Cost Management

**Remember to destroy resources when not in use to avoid AWS charges:**

```bash
terraform destroy
```

Estimated costs (us-west-2 region):
- c6i.4xlarge: ~$0.68/hour (~$490/month if running 24/7)
- EBS storage: ~$2/month for 20 GiB

## Troubleshooting

### Check Cloud-Init Logs

```bash
sudo cat /var/log/cloud-init-output.log
sudo cloud-init status
```

### Verify Ollama Installation

```bash
ollama --version
sudo systemctl status ollama
sudo journalctl -u ollama -n 50
```

### Manual Ollama Installation

If cloud-init fails, install Ollama manually:

```bash
sudo dnf install -y curl zstd
sudo mkdir -p /usr/local/bin /usr/local/lib/ollama
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst | zstd -d | sudo tar -xf - -C /usr/local
sudo ln -sf /usr/local/ollama /usr/local/bin/ollama

# Create systemd service from /etc/systemd/system/ollama.service (should be present from cloud-init)
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
```

## Customization

### Modify Cloud-Init Configuration

Edit scripts/server-conf.yaml to:
- Add additional users
- Install extra packages
- Run custom initialization commands

### Adjust Ollama Settings

Edit the systemd service after deployment:

```bash
sudo systemctl edit ollama
```

Add custom environment variables:

```ini
[Service]
Environment="OLLAMA_MODELS=/custom/path"
Environment="OLLAMA_HOST=0.0.0.0:11434"
```

Then restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## Next Steps

- Configure monitoring and logging
- Set up automated backups for model data
- Implement VPN or bastion host for enhanced security
- Consider using AWS Systems Manager Session Manager instead of SSH
- Add CloudWatch alarms for resource utilization

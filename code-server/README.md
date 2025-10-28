# Terraform recipe for launching a [code-server](https://github.com/coder/code-server) instance in AWS

This project is half experimentation half need. I want to be able to spinoff a web based development environment and I found code-server checking all my requirements. I'm fully aware of [vscode.dev](https://vscode.dev) and [Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare) I use them, but not what I want/need.

## Prepare ssh keys

```bash
ssh-keygen -t ed25519  -f keys/aws_key
```

## Instance Creation (Terraform)

Deploy the infrastructure using Terraform:

```bash
terraform init
terraform validate
terraform apply
```

## Provision instance with code-server

Configure the deployed instance with code-server:

```bash
# Set environment variables
export USER=coderadmin
export HOST=$(terraform output -raw public_ip)
export HOST_CONN=$USER@$HOST

# Add SSH key to agent (optional)
# Skip this step if your private key is not password-protected
eval $(ssh-agent)
ssh-add keys/aws_key

# Deploy code-server configuration
scp -i keys/aws_key conf/config.yaml ${HOST_CONN}:~/config.yaml

# Deploy and run setup script
scp -i keys/aws_key scripts/post_setup.sh ${HOST_CONN}:~/post_setup.sh
ssh -i keys/aws_key ${HOST_CONN} ./post_setup.sh
```

## Next Steps

- [ ] Configure nginx reverse proxy
- [ ] Set up default theme configuration
- [ ] Use chroot/nspawn? to further limit user to it's home directory or safe env

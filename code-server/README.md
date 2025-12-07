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
**Note**: The default EC2 instance type is [`t3.micro`](variables.tf#L13). To use a different instance type, override it during apply:

```bash
terraform apply -var="vm_type=t3.large"
```

## Provision instance with code-server

Configure the deployed instance with code-server:

```bash
./exec_setup.sh
```

Other preparation:
Once in the web based editor you can:
- Pick a theme
- Disable (or login to) Copilot
- Install golang dev plugin
- Setup a python run/debug plugin

## Remember to shutdown if not in use

```bash
terraform destroy
```


## Using HTTPS
This is out of scope, because I don't want to pay for the extra cost ;) [HTTPS documentation](https://coder.com/docs/code-server/guide).

## Next Steps
- [ ] Set up default theme configuration
- [ ] Use chroot/nspawn? to further limit user to it's home directory or safe env

# Set environment variables
export USER=coderadmin
export HOST=$(terraform output -raw public_ip)
export HOST_CONN=$USER@$HOST

# Deploy code-server configuration
scp -i keys/aws_key conf/config.yaml ${HOST_CONN}:~/config.yaml

# Deploy and run setup script
scp -i keys/aws_key scripts/post_setup.sh ${HOST_CONN}:~/post_setup.sh
ssh -i keys/aws_key ${HOST_CONN} ./post_setup.sh


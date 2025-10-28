#!/bin/bash -e

# This user should be present in the infrastructure previously created
# it will be the owner of the code-server
export SYSUSER="coder"

# Setup code-server
echo "Setting up code-server..."

# Move config to coder
PASS=$(openssl rand --base64 32)
echo "password: ${PASS}" >> ~/config.yaml
sudo mv ~/config.yaml /home/$SYSUSER/.config/code-server/config.yaml
sudo chown coder:coder /home/$SYSUSER/.config/code-server/config.yaml

# Install code-server
if [ ! -f /usr/local/bin/code-server ]; then
    curl -fsSL https://code-server.dev/install.sh | sh
fi

# Download Go tarball
curl -L -o /tmp/go1.21.5.linux-amd64.tar.gz https://go.dev/dl/go1.21.5.linux-amd64.tar.gz

# Remove existing Go installation
sudo rm -rf /usr/local/go

# Extract Go tarball
sudo tar -C /usr/local -xzf /tmp/go1.21.5.linux-amd64.tar.gz

# Add Go to PATH in .bashrc
if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" "$HOME/.bashrc"; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo -u $SYSUSER tee "/home/$SYSUSER/.bashrc"
fi

echo "Setup complete!"

echo "Starting server"
sudo systemctl enable --now code-server@$SYSUSER.service
echo "Use password: ${PASS}"

#!/bin/sh
# This script installs Ollama on Fedora-based systems (CPU-only mode).
# It detects the current operating system architecture and installs the appropriate version of Ollama.

## Note: this is a modified version of https://ollama.com/install.sh to support only dnf based Linux
## distros and CPU only inference.

set -eu

red="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 1 || :) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"

status() { echo ">>> $*" >&2; }
error() { echo "${red}ERROR:${plain} $*"; exit 1; }
warning() { echo "${red}WARNING:${plain} $*"; }

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf $TEMP_DIR; }
trap cleanup EXIT

available() { command -v $1 >/dev/null; }

[ "$(uname -s)" = "Linux" ] || error 'This script is intended to run on Linux only.'

# Verify this is a Fedora-based system
if [ ! -f "/etc/os-release" ]; then
    error "Cannot detect OS. This script is for Fedora-based systems only."
fi

. /etc/os-release

case $ID in
    fedora|rhel|centos|rocky|almalinux)
        ;;
    *)
        error "This script is for Fedora-based systems only. Detected: $ID"
        ;;
esac

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;
esac

VER_PARAM="${OLLAMA_VERSION:+?version=$OLLAMA_VERSION}"

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    if ! available sudo; then
        error "This script requires superuser permissions. Please re-run as root."
    fi
    SUDO="sudo"
fi

# Ensure required tools are available
for TOOL in curl zstd; do
    if ! available $TOOL; then
        status "Installing required tool: $TOOL"
        $SUDO dnf install -y $TOOL
    fi
done

# Function to download and extract with fallback from zst to tgz
download_and_extract() {
    local url_base="$1"
  Download and extract Ollama
download_and_extract() {
    local url_base="$1"
    local dest_dir="$2"
    local filename="$3"

    status "Downloading ${filename}.tar.zst"
    curl --fail --show-error --location --progress-bar \
        "${url_base}/${filename}.tar.zst${VER_PARAM}" | \
        zstd -d | $SUDO tar -xcal/bin /usr/bin /bin; do
    echo $PATH | grep -q $BINDIR && break || continue
done
OLLAMA_INSTALL_DIR=$(dirname ${BINDIR})

if [ -d "$OLLAMA_INSTALL_DIR/lib/ollama" ] ; then
    status "Cleaning up old version at $OLLAMA_INSTALL_DIR/lib/ollama"
    $SUDO rm -rf "$OLLAMA_INSTALL_DIR/lib/ollama"
fi
status "Installing ollama to $OLLAMA_INSTALL_DIR"
$SUDO install -o0 -g0 -m755 -d $BINDIR
$SUDO install -o0 -g0 -m755 -d "$OLLAMA_INSTALL_DIR/lib/ollama"
download_and_extract "https://ollama.com/download" "$OLLAMA_INSTALL_DIR" "ollama-linux-${ARCH}"

if [ "$OLLAMA_INSTALL_DIR/bin/ollama" != "$BINDIR/ollama" ] ; then
    status "Making ollama accessible in the PATH in $BINDIR"
    $SUDO ln -sf "$OLLAMA_INSTALL_DIR/ollama" "$BINDIR/ollama"
fi
# Install Ollama binary
BINDIR="/usr/local/bin"
OLLAMA_INSTALL_DIR="/usr/local"

if [ -d "$OLLAMA_INSTALL_DIR/lib/ollama" ] ; then
    status "Cleaning up old version at $OLLAMA_INSTALL_DIR/lib/ollama"
    $SUDO rm -rf "$OLLAMA_INSTALL_DIR/lib/ollama"
fi

status "Installing ollama to $OLLAMA_INSTALL_DIR"
$SUDO install -o0 -g0 -m755 -d $BINDIR
$SUDO install -o0 -g0 -m755 -d "$OLLAMA_INSTALL_DIR/lib/ollama"
# Create ollama user and configure systemd service
if ! id ollama >/dev/null 2>&1; then
    status "Creating ollama user..."
    $SUDO useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
fi

status "Adding current user to ollama group..."
$SUDO usermod -a -G ollama $(whoami)

# Detect CPU core count for optimal thread configuration
CPU_CORES=$(nproc)
status "Detected $CPU_CORES CPU cores for Intel Xeon optimization..."

status "Creating ollama systemd service (CPU-only mode optimized for Intel Xeon)..."
cat <<EOF | $SUDO tee /etc/systemd/system/ollama.service >/dev/null
[Unit]
Description=Ollama Service (CPU-only, Intel Xeon optimized)
After=network-online.target

[Service]
ExecStart=$BINDIR/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=$PATH"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
Environment="OLLAMA_NUM_THREADS=$CPU_CORES"
Environment="OLLAMA_RUNNERS_DIR=/usr/share/ollama/.ollama/runners"

[Install]
WantedBy=default.target
EOF

status "Enabling and starting ollama service..."
$SUDO systemctl daemon-reload
$SUDO systemctl enable ollama
$SUDO systemctl restart ollama

status "Installation complete!"
status "Ollama is installed in CPU-only mode"
status "The Ollama API is now available at 127.0.0.1:11434"
status "Run 'ollama' from the command line to get started."

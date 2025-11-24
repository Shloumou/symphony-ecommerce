#!/bin/bash

# Git Installation Fix Script for RHEL 9 (Unregistered System)
# This script provides multiple methods to install Git when standard repositories are unavailable

echo "=== Git Installation Fix for RHEL 9 ==="
echo ""

# Method 1: Try to enable CRB (CodeReady Builder) repository
echo "Method 1: Attempting to install via CRB repository..."
sudo dnf config-manager --set-enabled crb 2>/dev/null
sudo dnf install -y git 2>/dev/null

if command -v git &> /dev/null; then
    echo "✓ Git installed successfully via CRB!"
    git --version
    exit 0
fi

# Method 2: Try with EPEL
echo ""
echo "Method 2: Attempting to install via EPEL..."
sudo dnf install -y epel-release 2>/dev/null
sudo dnf install -y git 2>/dev/null

if command -v git &> /dev/null; then
    echo "✓ Git installed successfully via EPEL!"
    git --version
    exit 0
fi

# Method 3: Manual installation from tarball
echo ""
echo "Method 3: Manual installation (this may take a few minutes)..."
echo "Installing build dependencies..."
sudo dnf install -y curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel gcc make autoconf 2>/dev/null

if [ $? -eq 0 ]; then
    cd /tmp
    wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.43.0.tar.gz 2>&1 | tail -3
    tar -xzf git-2.43.0.tar.gz
    cd git-2.43.0
    make configure
    ./configure --prefix=/usr/local
    make all
    sudo make install
    
    if command -v git &> /dev/null; then
        echo "✓ Git installed successfully from source!"
        git --version
        exit 0
    fi
fi

# Method 4: Use Git from downloaded binary
echo ""
echo "Method 4: Installing pre-built Git binary..."
cd /tmp
wget https://github.com/git/git/releases/download/v2.43.0/git-2.43.0.tar.gz
tar -xzf git-2.43.0.tar.gz -C $HOME/.local/
export PATH="$HOME/.local/git-2.43.0/bin:$PATH"
echo 'export PATH="$HOME/.local/git-2.43.0/bin:$PATH"' >> ~/.bashrc

if command -v git &> /dev/null; then
    echo "✓ Git installed successfully as local binary!"
    git --version
    exit 0
fi

# If all methods fail
echo ""
echo "❌ All installation methods failed."
echo ""
echo "Manual Installation Options:"
echo "1. Register your RHEL system: sudo subscription-manager register"
echo "2. Use Git from a container: alias git='docker run -it --rm -v \$(pwd):/git alpine/git'"
echo "3. Contact your system administrator for repository access"
echo "4. Use GitHub Desktop or VS Code's built-in Git support"
echo ""
echo "Temporary workaround: Use VS Code Source Control"
echo "VS Code has built-in Git support that may work without system Git installed."

exit 1

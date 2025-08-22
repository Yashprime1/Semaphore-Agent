#!/bin/bash 
set -ex pipefail

# Set environment variables for non-interactive installation
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Function to handle errors
error_handler() {
    echo "ERROR: Script failed at line $1"
    echo "Command that failed: $2"
    exit 1
}

# Set up error handling
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

echo "Installing semaphoreci tools"

echo "Installing Semaphore CLI..."
# Install Semaphore CLI
curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz
mv sem /usr/local/bin/
chmod +x /usr/local/bin/sem

echo "Installing SPC (Semaphore Pipeline Compiler)..."
# Install SPC
curl -L https://github.com/semaphoreci/spc/releases/download/v1.12.1/spc_Linux_x86_64.tar.gz | tar -xz
mv spc /usr/local/bin/
chmod +x /usr/local/bin/spc

echo "Installing erlang..."
# Install Erlang
curl -L https://github.com/erlang/otp/releases/download/OTP-28.0.1/otp_src_28.0.1.tar.gz | tar -xz
# Install dependencies for Erlang, handling missing packages gracefully
apt-get update -y
# Enable universe repository which might contain wxGTK packages
if command -v add-apt-repository >/dev/null 2>&1; then
    add-apt-repository universe -y
else
    echo "add-apt-repository not available, trying alternative method"
    echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -cs) universe" >> /etc/apt/sources.list
fi
apt-get update -y
apt-get install -y build-essential autoconf m4 libncurses5-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils openjdk-11-jdk libssl-dev

# Try to install wxGTK packages with fallback options
echo "Attempting to install wxGTK packages..."
wx_installed=false
if apt-get install -y libwxgtk3.0-gtk3-dev 2>/dev/null; then
    echo "libwxgtk3.0-gtk3-dev installed successfully"
    wx_installed=true
elif apt-get install -y libwxgtk3.0-dev 2>/dev/null; then
    echo "libwxgtk3.0-dev installed as fallback"
    wx_installed=true
elif apt-get install -y libwxgtk3.0-gtk3-dev libwxgtk3.0-dev 2>/dev/null; then
    echo "wxGTK packages installed with alternative method"
    wx_installed=true
else
    echo "Warning: wxGTK packages not available, proceeding without GUI support"
    echo "This is expected behavior for some Ubuntu versions"
fi
cd otp_src_28.0.1/
# Configure Erlang, disabling wx if not available
if pkg-config --exists wx-config; then
    ./configure
else
    echo "Configuring Erlang without wx support"
    ./configure --without-wx
fi
make 
make install

echo "Installing When..."
#otp binary needed for when
curl -L https://github.com/renderedtext/when/releases/download/v1.2.1/when_otp_26 -o when_otp_26
mv when_otp_26 /usr/local/bin/when
chmod +x /usr/local/bin/when

echo "SemaphoreCI tools installation completed successfully!"
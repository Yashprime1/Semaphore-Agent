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

echo "Installing Erlang..."
apt-get -o DPkg::Lock::Timeout=300 install -y build-essential autoconf libtool
curl -L https://github.com/erlang/otp/releases/download/OTP-26.1.2/otp_src_26.1.2.tar.gz | tar -xz
cd otp_src_26.1.2
./configure --prefix=/opt/erlang
make
make install

# Add Erlang to PATH
echo "export PATH=/opt/erlang/bin:\$PATH" >> /etc/profile.d/semaphore.sh
echo "export ERLANG_HOME=/opt/erlang" >> /etc/profile.d/semaphore.sh

# Add to current session PATH
export PATH=/opt/erlang/bin:$PATH
export ERLANG_HOME=/opt/erlang

echo "Installing When..."
#otp binary needed for when
curl -L https://github.com/renderedtext/when/releases/download/v1.2.1/when_otp_26 -o when_otp_26
mv when_otp_26 /usr/local/bin/when
chmod +x /usr/local/bin/when

# Verify when installation
echo "Verifying when installation..."
/usr/local/bin/when --version || echo "Warning: when tool verification failed"

echo "SemaphoreCI tools installation completed successfully!"
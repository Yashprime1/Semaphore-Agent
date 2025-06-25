echo "Installing semaphoreci tools"

echo "Installing Semaphore CLI..."
# Install Semaphore CLI
curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz
sudo mv sem /usr/local/bin/
sudo chmod +x /usr/local/bin/sem

echo "Installing SPC (Semaphore Pipeline Compiler)..."
# Install SPC
curl -L https://github.com/semaphoreci/spc/releases/download/v1.12.1/spc_Linux_x86_64.tar.gz | tar -xz
sudo mv spc /usr/local/bin/
sudo chmod +x /usr/local/bin/spc


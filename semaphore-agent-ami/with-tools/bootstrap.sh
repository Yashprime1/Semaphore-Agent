echo "Installing semaphoreci tools"

echo "Installing Semaphore CLI..."
# Install Semaphore CLI
curl -L https://github.com/semaphoreci/cli/releases/latest/download/sem_linux_amd64.tar.gz | tar -xz
sudo mv sem /usr/local/bin/
sudo chmod +x /usr/local/bin/sem

echo "Installing SPC (Semaphore Pipeline Compiler)..."
# Install SPC
curl -L https://github.com/semaphoreci/spc/releases/latest/download/spc_linux_amd64.tar.gz | tar -xz
sudo mv spc /usr/local/bin/
sudo chmod +x /usr/local/bin/spc


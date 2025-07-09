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

echo "Installing erlang..."
# Install Erlang
curl -L https://github.com/erlang/otp/releases/download/OTP-28.0.1/otp_src_28.0.1.tar.gz | tar -xz
apt install -y build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils openjdk-11-jdk libssl-dev
cd otp_src_28.0.1/
./configure
make 
make install

echo "Installing When..."
#otp binary needed for when
curl -L https://github.com/renderedtext/when/releases/download/v1.2.1/when_otp_26 -o when_otp_26
mv when_otp_26 /usr/local/bin/when
chmod +x /usr/local/bin/when


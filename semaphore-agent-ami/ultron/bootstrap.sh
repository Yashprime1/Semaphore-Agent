echo "Installing build dependencies"

export JAVA_VERSION_MAJOR=8
export JAVA_VERSION_MINOR=332
export JAVA_VERSION_BUILD=08.1

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
security_group_id=$(curl -s http://169.254.169.254/latest/meta-data/security-groups | cut -d ' ' -f 1)
key_pair_name=$(curl -s http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key | cut -d ' ' -f 3)
region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

aws ec2 create-tags --resources $instance_id --region $region --tags \
  Key=packer-name,Value=semaphore-agent-ami-builder \
  Key=instance-id,Value=$instance_id \
  Key=security-group,Value=$security_group_id \
  Key=key-pair,Value=$key_pair_name


apt-get -o DPkg::Lock::Timeout=300 update -y

apt-get -o DPkg::Lock::Timeout=300 remove vim -y

apt-get -o DPkg::Lock::Timeout=300 install -y curl git openssl wget unzip ffmpeg

apt-get -o DPkg::Lock::Timeout=300 install -y python3-pip python3-dev python3-setuptools
apt-get -o DPkg::Lock::Timeout=300 install -y python3-pip --fix-missing


#apt-get install --only-upgrade snapd libssl1.0.0 policykit-1 libc-dev-bin libc-bin libc6 libc6-dev locales multiarch-support -y
apt-get -o DPkg::Lock::Timeout=300 install --only-upgrade snapd policykit-1 libc-dev-bin libc-bin libc6 libc6-dev locales -y

#packages need with some libraries to allow running browsers in headless mode
apt-get -o DPkg::Lock::Timeout=300 install -y libgbm-dev libxcomposite-dev libxrandr-dev libxkbcommon-dev libpangocairo-1.0-0 libatk1.0-0 libatk-bridge2.0-0
####
pip3 install awscli --upgrade --user

wget https://corretto.aws/downloads/resources/${JAVA_VERSION_MAJOR}.${JAVA_VERSION_MINOR}.${JAVA_VERSION_BUILD}/amazon-corretto-${JAVA_VERSION_MAJOR}.${JAVA_VERSION_MINOR}.${JAVA_VERSION_BUILD}-linux-x64.tar.gz >> /dev/null  \
    &&  tar -xzf amazon-corretto-${JAVA_VERSION_MAJOR}.${JAVA_VERSION_MINOR}.${JAVA_VERSION_BUILD}-linux-x64.tar.gz -C /opt \
    &&  rm -rf amazon-corretto-${JAVA_VERSION_MAJOR}.${JAVA_VERSION_MINOR}.${JAVA_VERSION_BUILD}-linux-x64.tar.gz


cd /tmp  \
    && wget https://corretto.aws/downloads/resources/11.0.19.7.1/amazon-corretto-11.0.19.7.1-linux-x64.tar.gz >> /dev/null  \
    &&  tar -xzf amazon-corretto-11.0.19.7.1-linux-x64.tar.gz -C /opt \
    &&  rm -rf amazon-corretto-11.0.19.7.1-linux-x64.tar.gz

curl --silent https://corretto.aws/downloads/resources/17.0.6.10.1/amazon-corretto-17.0.6.10.1-linux-x64.tar.gz |  tar -C /opt -xzf - && mv /opt/amazon-corretto-17.0.6.10.1-linux-x64 /opt/amazon-corretto-17-linux-x64

curl --silent https://corretto.aws/downloads/resources/18.0.2.9.1/amazon-corretto-18.0.2.9.1-linux-x64.tar.gz |  tar -C /opt -xzf - && mv /opt/amazon-corretto-18.0.2.9.1-linux-x64 /opt/amazon-corretto-18-linux-x64

#installing firefox for test cafe
mkdir -p /usr/lib/firefox
wget --no-verbose https://ftp.mozilla.org/pub/firefox/releases/130.0/linux-x86_64/en-US/firefox-130.0.tar.bz2
tar -xjf firefox-130.0.tar.bz2 -C /usr/lib/firefox
ln -s /usr/lib/firefox/firefox/firefox /usr/bin/firefox
rm -rf firefox-130.0.tar.bz2


#installing git lfs latest version
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get install git-lfs
git lfs install

curl -s https://archive.apache.org/dist/ant/binaries/apache-ant-1.9.3-bin.tar.gz |   tar -v -xz -C /opt/

curl -s https://dl.google.com/go/go1.19.3.linux-amd64.tar.gz| tar -v -C /opt/ -xz

# Install Azure CLI - this is NOT meant to talk to Azure, but rather to talk to Azurite in order to facilitate an OAuth token exchange.
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Download and install jq
aws s3 cp s3://system-sharedresources-ssms3bucket-w1ud0dbtcbgk/semaphore-agent/jq/jq-1.7.1.tar .
tar -xvf jq-1.7.1.tar
cd jq-1.7.1
apt-get install -y autoconf libtool build-essential
autoreconf -i
./configure
make
make install
ln -s /usr/local/bin/jq /usr/bin/jq

#installing google chrome headless for test cafe
wget --no-verbose -O /tmp/chrome.deb https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_135.0.7049.114-1_amd64.deb \
  && apt install -y /tmp/chrome.deb \
  && rm /tmp/chrome.deb

# Download and install NodeJS.
aws s3 cp s3://system-sharedresources-ssms3bucket-w1ud0dbtcbgk/semaphore-agent/node-v14-18-2/node-v14.18.2-linux-x64.tar - |  tar -v -xz -C /opt/
aws s3 cp s3://system-sharedresources-ssms3bucket-w1ud0dbtcbgk/semaphore-agent/node-v18-18-2/node-v18.18.2-linux-x64.tar - |  tar -v -xz -C /opt/
aws s3 cp s3://system-sharedresources-ssms3bucket-w1ud0dbtcbgk/semaphore-agent/node-v20-10-0/node-v20.10.0-linux-x64.tar - |  tar -v -xz -C /opt/
export PATH=$PATH:/opt/node-v14.18.2-linux-x64/bin
export PATH=$PATH:/opt/node-v20.10.0-linux-x64/bin
npm install --global yarn
echo 'export PATH=/opt/node-v14.18.2-linux-x64/bin:$PATH' >> /etc/profile.d/semaphore.sh
echo 'export PATH=/opt/node-v20.10.0-linux-x64/bin:$PATH' >> /etc/profile.d/semaphore.sh
echo 'export SEMAPHORE_TOOLBOX_VERSION=v1.26.0' >> /etc/profile.d/semaphore.sh

curl -fL https://getcli.jfrog.io | sh &&  mv jfrog /usr/bin/ &&  chmod +x /usr/bin/jfrog

echo "Set maven, java and ant home directories in PATH"
sed -i 's/^export JAVA_HOME.*/export JAVA_HOME=\/opt\/amazon-corretto-8.332.08.1-linux-x64/' /etc/profile.d/semaphore.sh
sed -i 's/^export M2_HOME.*/export M2_HOME=\/opt\/apache-maven-3.9.4/' /etc/profile.d/semaphore.sh
sed -i 's/^export MAVEN_HOME.*/export MAVEN_HOME=\/opt\/apache-maven-3.9.4/' /etc/profile.d/semaphore.sh
echo "Fix semaphore agent heap size(XMX)"
sed -i 's@.*MARKER.*@sed -i "s/-Xmx256m/-Xmx1g/" $startupScript@' /opt/semaphore-agent/bin/semaphore-agent

echo 'export PATH=/opt/amazon-corretto-11.0.19.7.1-linux-x64/bin:/opt/apache-maven-3.9.4/bin:$PATH' >> /etc/profile.d/semaphore.sh

echo "Add private key to semaphore home directory"
echo "export MAVEN_HOME=/opt/apache-maven-3.9.4" >> /etc/profile.d/semaphore.sh
# Source the environment and create override
source /etc/profile.d/semaphore.sh
sudo tee /etc/systemd/system/semaphore-agent.service.d/environment.conf << EOF
[Service]
Environment="SEMAPHORE_TOOLBOX_VERSION=$SEMAPHORE_TOOLBOX_VERSION"
Environment="MAVEN_HOME=$MAVEN_HOME"
Environment="PATH=$PATH"
EOF
echo "Setting maven home"
echo "fs.file-max=1000000" >> /etc/sysctl.conf
ls -lrth /etc/sysctl.conf
ls -lrth /etc/security/limits.conf
echo "semaphore           soft    nofile          900000" >> /etc/security/limits.conf
echo "semaphore           hard    nofile          900000" >> /etc/security/limits.conf

mkdir -p /home/semaphore/semaphore-agent-home/logs
chown -R semaphore:users /home/semaphore/semaphore-agent-home
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.8.1.linux-amd64.tar.gz
mv node_exporter-1.8.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.8.1.linux-amd64*
bash -c 'cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:8090

[Install]
WantedBy=multi-user.target
EOF'
sudo systemctl daemon-reload
sudo systemctl unmask node_exporter
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
echo "Bootstrapped semaphore agent"

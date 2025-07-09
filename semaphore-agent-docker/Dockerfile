FROM semaphoreci/agent:v2.3.0

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    unzip \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop \
    libxml2-utils \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Build and install Erlang
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/

# Install Semaphore CLI tools
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && mv sem /usr/local/bin/ \
    && chmod +x /usr/local/bin/sem    

# Install Semaphore Toolbox
RUN mkdir -p ~/.toolbox \
    && curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C ~/.toolbox --strip-components=1 \
    && bash ~/.toolbox/install-toolbox

# Create semaphore user's toolbox directory and copy tools
ENV USER=semaphore

RUN mkdir -p /home/${USER}/.toolbox \
    && cp -r /root/.toolbox/* /home/${USER}/.toolbox/ \
    && chown -R ${USER}:${USER} /home/${USER}/.toolbox

# Create symlinks in /usr/local/bin for semaphore user access
RUN source /home/${USER}/.toolbox/libcheckout \
    && source /home/${USER}/.toolbox/libchecksum \
    && ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache \
    && ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact \
    && ln -sf /home/${USER}/.toolbox/sem-context /usr/local/bin/sem-context \
    && ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry \
    && ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results \
    && ln -sf /home/${USER}/.toolbox/checkout /usr/local/bin/libcheckout
    

RUN mkdir -p /opt/semaphore

# Copy shutdown hook script
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh

RUN chmod +x /opt/semaphore/shutdown \
    && chmod +x /opt/semaphore/entrypoint.sh

RUN chown ${USER}:${USER} /opt/semaphore/shutdown \
    && chown ${USER}:${USER} /opt/semaphore/entrypoint.sh

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
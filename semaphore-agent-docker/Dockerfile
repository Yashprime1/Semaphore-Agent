# Build stage
FROM semaphoreci/agent:v2.3.0 as builder

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
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
    && rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Build and install Erlang
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure --disable-debug --disable-hipe --disable-javac --without-javac \
    && make -j$(nproc) \
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

# Final stage
FROM semaphoreci/agent:v2.3.0

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install runtime dependencies with proper Python setup
RUN apt-get update && \
    # Find the correct libssl package name
    SSL_PKG=$(apt-cache search '^libssl[0-9]' | head -1 | cut -d' ' -f1) && \
    apt-get install -y --no-install-recommends \
    jq \
    git \
    libncurses5 \
    python3.13 \
    python3.13-pip \
    python3.13-dev \
    libpython3.13-dev \
    ${SSL_PKG:-libssl-dev} \
    openssh-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*


# Copy only the required binaries from the builder stage
COPY --from=builder /usr/local/bin/aws /usr/local/bin/
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /usr/local/bin/sem /usr/local/bin/
COPY --from=builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=builder /usr/local/bin/erl /usr/local/bin/
COPY --from=builder /usr/local/bin/erlc /usr/local/bin/
COPY --from=builder /root/.toolbox /root/.toolbox

# Create semaphore user's toolbox directory
ENV USER=semaphore

RUN mkdir -p /home/${USER}/.toolbox \
    && cp -r /root/.toolbox/* /home/${USER}/.toolbox/ \
    && chown -R ${USER}:${USER} /home/${USER}/.toolbox

# Create scripts and symlinks
RUN echo '#!/bin/bash' > /usr/local/bin/checkout \
    && echo 'source /home/semaphore/.toolbox/libcheckout' >> /usr/local/bin/checkout \
    && echo 'checkout "$@"' >> /usr/local/bin/checkout \
    && chmod +x /usr/local/bin/checkout \
    && echo '#!/bin/bash' > /usr/local/bin/checksum \
    && echo 'source /home/semaphore/.toolbox/libchecksum' >> /usr/local/bin/checksum \
    && echo 'checksum "$@"' >> /usr/local/bin/checksum \
    && chmod +x /usr/local/bin/checksum

# Create symlinks for toolbox scripts
RUN ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache \
    && ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact \
    && ln -sf /home/${USER}/.toolbox/sem-context /usr/local/bin/sem-context \
    && ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry \
    && ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results

RUN mkdir -p /opt/semaphore

# Copy shutdown hook script and entrypoint
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh

RUN chmod +x /opt/semaphore/shutdown \
    && chmod +x /opt/semaphore/entrypoint.sh \
    && chown ${USER}:${USER} /opt/semaphore/shutdown \
    && chown ${USER}:${USER} /opt/semaphore/entrypoint.sh


ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
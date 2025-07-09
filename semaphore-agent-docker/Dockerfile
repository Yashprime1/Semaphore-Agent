# Build stage
FROM semaphoreci/agent:v2.3.0 AS builder

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
    ca-certificates

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Build Erlang
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz && \
    cd otp_src_26.2.5.2/ && \
    ./configure \
        --prefix=/opt/erlang \
        --disable-debug \
        --disable-silent-rules \
        --enable-threads \
        --enable-kernel-poll \
        --enable-hipe \
        --without-javac \
        --without-odbc \
        --without-wx \
        --without-debugger \
        --without-observer \
        --without-et \
        --without-megaco \
        --without-diameter && \
    make -j$(nproc) && \
    make install

# Install Semaphore CLI tools
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz && \
    mv sem /usr/local/bin/ && \
    chmod +x /usr/local/bin/sem

# Install Semaphore Toolbox
RUN mkdir -p ~/.toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C ~/.toolbox --strip-components=1 && \
    bash ~/.toolbox/install-toolbox

# Final stage - runtime
FROM semaphoreci/agent:v2.3.0

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore
ENV PATH="/opt/erlang/bin:$PATH"

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    git \
    openssh-client \
    ca-certificates \
    libssl3 \
    libncurses6 \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy built artifacts from builder stage
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /opt/erlang /opt/erlang
COPY --from=builder /usr/local/bin/sem /usr/local/bin/sem
COPY --from=builder /root/.toolbox /root/.toolbox

# Setup toolbox for semaphore user
RUN mkdir -p /home/${USER}/.toolbox && \
    cp -r /root/.toolbox/* /home/${USER}/.toolbox/ && \
    chown -R ${USER}:${USER} /home/${USER}/.toolbox

# Create standalone scripts
RUN echo '#!/bin/bash\nsource /home/semaphore/.toolbox/libcheckout\ncheckout "$@"' > /usr/local/bin/checkout && \
    echo '#!/bin/bash\nsource /home/semaphore/.toolbox/libchecksum\nchecksum "$@"' > /usr/local/bin/checksum && \
    chmod +x /usr/local/bin/checkout /usr/local/bin/checksum

# Create symlinks for toolbox scripts
RUN ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache && \
    ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact && \
    ln -sf /home/${USER}/.toolbox/sem-context /usr/local/bin/sem-context && \
    ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry && \
    ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results

RUN mkdir -p /opt/semaphore

# Copy shutdown hook script
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh

RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh && \
    chown ${USER}:${USER} /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
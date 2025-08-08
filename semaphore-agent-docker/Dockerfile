#####################
# 1. Build Stage     #
#####################
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        autoconf \
        libncurses5-dev \
        libssl-dev \
        zlib1g-dev \
        perl \
        git \
        ca-certificates \
        unzip \
        jq \
        gnupg \
        software-properties-common \
        lsb-release \
        libc6 \
        libssl3 \
        libncurses6 \
        zlib1g \
        tzdata \
        libffi8 \
        libexpat1 \
        libbz2-1.0 \
        liblzma5 \
        libreadline8 \
        libsqlite3-0 \
        libuuid1

# Build Erlang
RUN curl -fsSL https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
        --prefix=/opt/erlang \
        --enable-smp-support \
        --disable-debug \
        --disable-hipe \
        --disable-sctp \
        --without-javac \
        --without-wx \
        --without-observer \
        --without-debugger \
        --without-et \
        --without-gs \
        --without-ic \
        --without-orber \
        --without-cosTransactions \
        --without-cosEvent \
        --without-cosTime \
        --without-cosNotification \
        --without-cosProperty \
        --without-cosFileTransfer \
        --without-cosEventDomain \
        --without-diameter \
        --without-eldap \
        --without-erl_docgen \
        --without-ftp \
        --without-jinterface \
        --without-megaco \
        --without-odbc \
        --without-reltool \
        --without-ssh \
        --without-tftp \
        --without-typer \
        --without-snmp \
        --without-mnesia \
        --without-eunit \
        --without-common_test \
        --without-dialyzer \
        --without-xmerl \
        --without-parsetools \
        --without-syntax_tools \
        --without-tools \
        --without-runtime_tools \
        --without-inets \
        --without-edoc \
        --enable-shared-zlib \
        --enable-static-drivers \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/ \
    && strip --strip-unneeded /opt/erlang/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /opt/erlang -name "*.so" -exec strip --strip-unneeded {} \; 2>/dev/null || true \
    && find /opt/erlang -type d -name "src" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -name "*.beam" ! -path "*/ebin/*" -delete 2>/dev/null || true

# Download Semaphore CLI and Toolbox
RUN curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && strip --strip-unneeded sem 2>/dev/null || true \
    && mkdir -p /toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 \
    && find /toolbox -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true

# Install Python 3.13
RUN curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get\&search=0xBA6932366A755776 | \
        gpg --dearmor -o /usr/share/keyrings/deadsnakes-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/deadsnakes-archive-keyring.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble main" \
        > /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.13 \
        python3.13-dev \
        libpython3.13-stdlib \
        libpython3.13 \
    && ln -sf /usr/bin/python3.13 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.13 /usr/bin/python

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf awscliv2.zip aws

# Extract Semaphore agent from official image
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

#######################
# 2. Final Stage      #
#######################
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC

# Create Semaphore user
ENV USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/opt/erlang/bin:/usr/local/bin:/usr/local/aws-cli/v2/current/bin:${PATH}"
ENV BASH_ENV="${HOME}/.bashrc"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

RUN groupadd -g 1001 ${USER} 2>/dev/null || true \
    && useradd -u 1001 -g ${USER} -m -s /bin/bash ${USER} 2>/dev/null || true

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        curl \
        jq \
        libc6 \
        libssl3 \
        libncurses6 \
        zlib1g \
        tzdata \
        libffi8 \
        libexpat1 \
        libbz2-1.0 \
        liblzma5 \
        libreadline8 \
        libsqlite3-0 \
        libuuid1 \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*

# Copy all binaries and tools from builder stage
COPY --from=builder --chown=root:root /opt/erlang /opt/erlang
COPY --from=builder --chown=root:root /sem /usr/local/bin/sem
COPY --from=builder --chown=root:root /toolbox /root/.toolbox
COPY --from=builder --chown=root:root /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder --chown=root:root /usr/bin/python3.13 /usr/bin/python3.13
COPY --from=builder --chown=root:root /usr/bin/python3 /usr/bin/python3
COPY --from=builder --chown=root:root /usr/bin/python /usr/bin/python
COPY --from=builder --chown=root:root /usr/lib/python3.13 /usr/lib/python3.13
COPY --from=builder --chown=root:root /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder --chown=root:root /usr/local/bin/aws_completer /usr/local/bin/aws_completer

# Copy Semaphore agent
COPY --from=agent-extractor --chown=root:root /opt/semaphore/agent /opt/semaphore/agent

# Setup toolbox for semaphore user
RUN mkdir -p /home/${USER}/.toolbox \
    && cp -r /root/.toolbox/* /home/${USER}/.toolbox/ \
    && chown -R ${USER}:${USER} /home/${USER}/.toolbox \
    && chmod +x /home/${USER}/.toolbox/* \
    && echo '. /home/semaphore/.toolbox/libcheckout' >> /home/${USER}/.bashrc \
    && echo '. /home/semaphore/.toolbox/libchecksum' >> /home/${USER}/.bashrc \
    && chown ${USER}:${USER} /home/${USER}/.bashrc \
    && ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache \
    && ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact \
    && ln -sf /home/${USER}/.toolbox/sem-context /usr/local/bin/sem-context \
    && ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry \
    && ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results \
    && chmod +x /opt/semaphore/agent /usr/local/bin/sem \
    && mkdir -p /opt/semaphore \
    && chown -R ${USER}:${USER} /opt/semaphore \
    && ldconfig

# Add entrypoint and shutdown scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Final cleanup
RUN find /usr -name "*.a" -delete 2>/dev/null || true \
    && find /usr -name "*.la" -delete 2>/dev/null || true \
    && find /usr -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /root/.toolbox \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/docs 2>/dev/null || true

USER ${USER}
WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
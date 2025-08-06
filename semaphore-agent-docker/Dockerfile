# Stage 1: Build minimal Erlang from source
FROM alpine:3.18 AS erlang-builder

RUN apk add --no-cache build-base curl autoconf ncurses-dev openssl-dev zlib-dev perl

# Build ultra-minimal Erlang with only essential components
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
        --prefix=/usr/local \
        --enable-smp-support \
        --disable-debug \
        --disable-hipe \
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
    && make -j$(nproc) \
    && make install \
    && strip /usr/local/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /usr/local/lib/erlang -name "*.so" -exec strip {} \; 2>/dev/null || true \
    && rm -rf /usr/local/lib/erlang/lib/*/src \
    && rm -rf /usr/local/lib/erlang/lib/*/examples \
    && rm -rf /usr/local/lib/erlang/lib/*/doc \
    && cd .. && rm -rf otp_src_26.2.5.2/

# Stage 2: Get AWS CLI (pip version - much smaller than binary)
FROM python:3.11-alpine AS aws-builder
RUN pip install --no-cache-dir awscli==1.32.106 \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /root/.cache

# Stage 3: Get Semaphore tools
FROM alpine:3.18 AS tools-builder
RUN apk add --no-cache curl tar

# Get Semaphore CLI
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz

# Get Semaphore Toolbox
RUN mkdir -p /toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 && \
    echo "Available toolbox files:" && find /toolbox -type f

# Stage 4: Extract the real Semaphore agent
FROM semaphoreci/agent:v2.3.0 AS agent-extractor
# This stage is just to extract the agent binary

# Stage 5: Final optimized image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore
ENV HOME=/home/${USER}

# Create semaphore user
RUN groupadd -g 1000 ${USER} && \
    useradd -u 1000 -g ${USER} -m -s /bin/bash ${USER}

# Install only essential packages in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        curl \
        jq \
        python3 \
        python3-distutils \
        libc6 \
        libssl3 \
        libncurses6 \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* \
    && rm -rf /usr/share/doc /usr/share/man /usr/share/info /usr/share/locale /usr/share/pixmaps /usr/share/zoneinfo

# Copy the real Semaphore agent binary
COPY --from=agent-extractor /opt/semaphore/agent /opt/semaphore/agent
RUN chmod +x /opt/semaphore/agent

# Copy AWS CLI (pip version - much smaller)
COPY --from=aws-builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=aws-builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy Semaphore CLI
COPY --from=tools-builder /sem /usr/local/bin/sem
RUN chmod +x /usr/local/bin/sem

# Copy minimal Erlang installation
COPY --from=erlang-builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/escript

# Copy Semaphore Toolbox and create essential tools
COPY --from=tools-builder /toolbox ${HOME}/.toolbox
RUN chown -R ${USER}:${USER} ${HOME}/.toolbox && \
    # Create working versions of toolbox commands
    echo '#!/bin/bash' > /usr/local/bin/cache && \
    echo 'if [ -x "${HOME}/.toolbox/cache" ]; then exec "${HOME}/.toolbox/cache" "$@"; else echo "cache: $*" >&2; fi' >> /usr/local/bin/cache && \
    echo '#!/bin/bash' > /usr/local/bin/artifact && \
    echo 'if [ -x "${HOME}/.toolbox/artifact" ]; then exec "${HOME}/.toolbox/artifact" "$@"; else echo "artifact: $*" >&2; fi' >> /usr/local/bin/artifact && \
    echo '#!/bin/bash' > /usr/local/bin/retry && \
    echo 'if [ -x "${HOME}/.toolbox/retry" ]; then exec "${HOME}/.toolbox/retry" "$@"; else echo "retry: $*" >&2; fi' >> /usr/local/bin/retry && \
    echo '#!/bin/bash' > /usr/local/bin/sem-context && \
    echo 'if [ -x "${HOME}/.toolbox/sem-context" ]; then exec "${HOME}/.toolbox/sem-context" "$@"; else' >> /usr/local/bin/sem-context && \
    echo '  case "$1" in get) echo "${!2}";; put) export "$2"="$3";; *) echo "Usage: sem-context {get|put} <key> [value]" >&2; exit 1;; esac' >> /usr/local/bin/sem-context && \
    echo 'fi' >> /usr/local/bin/sem-context && \
    echo '#!/bin/bash' > /usr/local/bin/test-results && \
    echo 'if [ -x "${HOME}/.toolbox/test-results" ]; then exec "${HOME}/.toolbox/test-results" "$@"; else echo "test-results: $*" >&2; fi' >> /usr/local/bin/test-results && \
    chmod +x /usr/local/bin/cache /usr/local/bin/artifact /usr/local/bin/retry /usr/local/bin/sem-context /usr/local/bin/test-results

# Setup toolbox environment
RUN echo '. ${HOME}/.toolbox/libcheckout 2>/dev/null || true' >> ${HOME}/.bashrc && \
    echo '. ${HOME}/.toolbox/libchecksum 2>/dev/null || true' >> ${HOME}/.bashrc && \
    chown ${USER}:${USER} ${HOME}/.bashrc && \
    mkdir -p /opt/semaphore && \
    chown -R ${USER}:${USER} /opt/semaphore

# Final aggressive cleanup to minimize size
RUN find /usr -name "*.a" -delete 2>/dev/null || true && \
    find /usr -name "*.la" -delete 2>/dev/null || true && \
    rm -rf /usr/include/* 2>/dev/null || true && \
    rm -rf /var/log/* 2>/dev/null || true && \
    rm -rf /usr/lib/systemd 2>/dev/null || true && \
    find /usr/local -name "*.pyc" -delete 2>/dev/null || true

# Copy essential scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

USER ${USER}
WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
# Stage 1: Build a minimal Erlang/OTP from source on Alpine
FROM alpine:3.18 AS erlang-builder

# Install build dependencies in a single step
RUN apk add --no-cache \
    build-base \
    curl \
    autoconf \
    ncurses-dev \
    openssl-dev \
    zlib-dev \
    perl

# Build and install a minimal Erlang/OTP
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
        --without-asn1 \
        --without-crypto \
        --without-public_key \
        --without-ssl \
        --enable-shared-zlib \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/ \
    && strip /usr/local/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /usr/local/lib/erlang -name "*.so" -exec strip {} \; 2>/dev/null || true

# Stage 2: AWS CLI builder to minimize size
FROM alpine:3.18 AS aws-builder
RUN apk add --no-cache curl unzip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --install-dir /aws-cli --bin-dir /usr/local/bin \
    && rm -rf awscliv2.zip aws/ \
    && rm -rf /aws-cli/v2/*/dist/awscli/examples \
    && rm -rf /aws-cli/v2/*/dist/awscli/topics \
    && find /aws-cli -name "*.pyc" -delete \
    && find /aws-cli -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Stage 3: Toolbox builder
FROM alpine:3.18 AS toolbox-builder
RUN apk add --no-cache curl tar
RUN mkdir -p /toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 && \
    # List all files to debug
    echo "All toolbox files:" && find /toolbox -type f && \
    # Keep only essential tools
    find /toolbox -type f \
        ! -name "cache" \
        ! -name "artifact" \
        ! -name "retry" \
        ! -name "sem-context" \
        ! -name "test-results" \
        ! -name "libcheckout" \
        ! -name "libchecksum" \
        ! -name "install-toolbox" \
        -delete && \
    echo "Kept toolbox files:" && find /toolbox -type f && \
    chmod +x /toolbox/* 2>/dev/null || true

# Stage 4: Semaphore CLI builder
FROM alpine:3.18 AS cli-builder
RUN apk add --no-cache curl tar
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && chmod +x sem

# Stage 5: Final minimal image
FROM semaphoreci/agent:v2.3.0

# Set up user and timezone
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore
ENV HOME=/home/${USER}

# Install only absolutely essential dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        jq \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/*

# Copy AWS CLI (minimized)
COPY --from=aws-builder /aws-cli /usr/local/aws-cli
COPY --from=aws-builder /usr/local/bin/aws /usr/local/bin/aws
RUN ln -sf /usr/local/aws-cli/v2/current/bin/aws_completer /usr/local/bin/aws_completer

# Copy Semaphore CLI
COPY --from=cli-builder /sem /usr/local/bin/sem
RUN chmod +x /usr/local/bin/sem

# Copy minimal Erlang installation
COPY --from=erlang-builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/escript

# Copy Semaphore Toolbox
COPY --from=toolbox-builder /toolbox ${HOME}/.toolbox
RUN chown -R ${USER}:${USER} ${HOME}/.toolbox \
    && chmod +x ${HOME}/.toolbox/* 2>/dev/null || true \
    && mkdir -p /opt/semaphore \
    && chown ${USER}:${USER} /opt/semaphore

# Setup symbolic links and environment
RUN ln -sf ${HOME}/.toolbox/cache /usr/local/bin/cache 2>/dev/null || true && \
    ln -sf ${HOME}/.toolbox/artifact /usr/local/bin/artifact 2>/dev/null || true && \
    ln -sf ${HOME}/.toolbox/retry /usr/local/bin/retry 2>/dev/null || true && \
    (ln -sf ${HOME}/.toolbox/sem-context /usr/local/bin/sem-context 2>/dev/null || \
     echo -e '#!/bin/bash\ncase "$1" in\n  "get") echo "${!2}" 2>/dev/null || echo ""; ;;\n  "put") echo "Context set: $2=$3" >&2; export "$2"="$3"; ;;\n  *) echo "Usage: sem-context {get|put} <key> [value]" >&2; exit 1; ;;\nesac' > /usr/local/bin/sem-context && chmod +x /usr/local/bin/sem-context) && \
    (ln -sf ${HOME}/.toolbox/test-results /usr/local/bin/test-results 2>/dev/null || \
     echo -e '#!/bin/bash\necho "test-results: $*" >&2' > /usr/local/bin/test-results && chmod +x /usr/local/bin/test-results) && \
    echo '. /home/semaphore/.toolbox/libcheckout' >> ${HOME}/.bashrc && \
    echo '. /home/semaphore/.toolbox/libchecksum' >> ${HOME}/.bashrc && \
    chown ${USER}:${USER} ${HOME}/.bashrc

# Copy essential scripts and set permissions
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Debug: List all available executables
RUN echo "=== Debug Info ===" && \
    echo "Toolbox contents:" && ls -la ${HOME}/.toolbox/ && \
    echo "Symlinks in /usr/local/bin:" && ls -la /usr/local/bin/ | grep toolbox && \
    echo "=================="

USER ${USER}
WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
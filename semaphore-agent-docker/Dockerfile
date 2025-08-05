# Build stage for Erlang/OTP
FROM alpine:3.18 AS erlang-builder
RUN apk add --no-cache \
    build-base \
    curl \
    autoconf \
    ncurses-dev \
    openssl-dev \
    zlib-dev \
    perl

# Build minimal Erlang/OTP
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
        --prefix=/usr/local \
        --enable-smp-support \
        --disable-debug \
        --disable-hipe \
        --disable-javac \
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
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/

# Aggressive Erlang cleanup - keep only absolute essentials
RUN cd /usr/local && \
    # Remove all documentation and examples
    find . -name "doc" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "examples" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "src" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "include" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find . -name "*.html" -delete && \
    find . -name "*.pdf" -delete && \
    find . -name "*.ps" -delete && \
    find . -name "*.png" -delete && \
    find . -name "*.jpg" -delete && \
    find . -name "*.gif" -delete && \
    # Strip binaries
    find . -name "*.so" -exec strip --strip-unneeded {} \; 2>/dev/null || true && \
    find . -name "*.beam" -exec strip --strip-debug {} \; 2>/dev/null || true && \
    find . -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true

# Download stage - use minimal alpine
FROM alpine:3.18 AS downloader
RUN apk add --no-cache curl

# Download only what's absolutely necessary
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz

# Create minimal toolbox (only essential scripts)
RUN mkdir -p /toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 && \
    # Keep only essential tools
    cd /toolbox && \
    find . -type f ! -name "cache" ! -name "artifact" ! -name "retry" ! -name "libcheckout" ! -name "libchecksum" ! -name "install-toolbox" -delete

# Minimal AWS CLI alternative - use aws-cli-v2 minimal
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    rm awscliv2.zip

# Final stage - keep original base
FROM semaphoreci/agent:v2.3.0
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore

# Install only essential runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libssl1.1 \
    libncurses5 \
    libtinfo5 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /var/cache/apt/*

# Copy minimal Erlang installation - only core components
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/
COPY --from=erlang-builder /usr/local/lib/erlang/erts-* /usr/local/lib/erlang/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/kernel-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/stdlib-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/sasl-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/crypto-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/ssl-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/public_key-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/lib/asn1-* /usr/local/lib/erlang/lib/
COPY --from=erlang-builder /usr/local/lib/erlang/releases /usr/local/lib/erlang/releases

# Install minimal AWS CLI
COPY --from=downloader /aws /tmp/aws
RUN /tmp/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin && \
    rm -rf /tmp/aws && \
    # Remove AWS CLI bloat
    rm -rf /usr/local/aws-cli/v2/*/dist/awscli/examples && \
    rm -rf /usr/local/aws-cli/v2/*/dist/awscli/topics && \
    rm -rf /usr/local/aws-cli/v2/*/dist/awscli/botocore/data/*/2* && \
    find /usr/local/aws-cli -name "*.pyc" -delete && \
    find /usr/local/aws-cli -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Copy Semaphore CLI
COPY --from=downloader /sem /usr/local/bin/sem
RUN chmod +x /usr/local/bin/sem

# Install minimal Toolbox
COPY --from=downloader /toolbox /home/${USER}/.toolbox
RUN chown -R ${USER}:${USER} /home/${USER}/.toolbox && \
    ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache && \
    ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact && \
    ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry

# Setup minimal user environment
RUN echo '. /home/semaphore/.toolbox/libcheckout' >> /home/${USER}/.bashrc && \
    echo '. /home/semaphore/.toolbox/libchecksum' >> /home/${USER}/.bashrc && \
    mkdir -p /opt/semaphore && \
    chown -R ${USER}:${USER} /opt/semaphore /home/${USER}

# Copy essential scripts
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh && \
    chown ${USER}:${USER} /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Final aggressive cleanup
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    find /usr/local -name "*.a" -delete && \
    find /usr/local -name "*.la" -delete

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
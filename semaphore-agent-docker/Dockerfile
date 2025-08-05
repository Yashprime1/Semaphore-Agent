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

# Build and install a minimal Erlang/OTP, then aggressively clean up
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
        --prefix=/usr/local \
        --enable-smp-support \
        --disable-debug \
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
    && rm -rf otp_src_26.2.5.2/ \
    # Now, a new aggressive cleanup step to strip everything
    && find /usr/local -name "*.so" -exec strip --strip-unneeded {} + 2>/dev/null || true \
    && find /usr/local -name "*.beam" -exec strip --strip-debug {} + 2>/dev/null || true \
    && find /usr/local -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true \
    && rm -rf /usr/local/lib/erlang/lib/*/doc \
    && rm -rf /usr/local/lib/erlang/lib/*/examples \
    && rm -rf /usr/local/lib/erlang/lib/*/src \
    && find /usr/local -name "*.a" -delete -o -name "*.la" -delete

# Stage 2: The final image
FROM semaphoreci/agent:v2.3.0

# Set up user and timezone
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore

# This is the single, monolithic RUN command for maximum size reduction
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libssl1.1 \
    libncurses5 \
    libtinfo5 \
    zlib1g \
    unzip && \
    mkdir -p /tmp/downloads && \
    # AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/downloads/awscliv2.zip" && \
    unzip /tmp/downloads/awscliv2.zip -d /tmp/downloads/ && \
    /tmp/downloads/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin && \
    # Semaphore CLI
    curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/sem && \
    # Semaphore Toolbox
    mkdir -p /home/${USER}/.toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /home/${USER}/.toolbox --strip-components=1 && \
    find /home/${USER}/.toolbox -type f ! -name "cache" ! -name "artifact" ! -name "retry" ! -name "libcheckout" ! -name "libchecksum" ! -name "install-toolbox" -delete && \
    # Cleanup all the temporary files and caches
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* /usr/local/aws-cli/v2/*/dist/awscli/examples /usr/local/aws-cli/v2/*/dist/awscli/topics && \
    find /usr/local/aws-cli -name "*.pyc" -delete && \
    find /usr/local/aws-cli -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null && \
    # Create required directories and set permissions
    mkdir -p /opt/semaphore && \
    chown -R ${USER}:${USER} /opt/semaphore /home/${USER} && \
    # Setup links and environment for the user
    ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache && \
    ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact && \
    ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry && \
    echo '. /home/semaphore/.toolbox/libcheckout' >> /home/${USER}/.bashrc && \
    echo '. /home/semaphore/.toolbox/libchecksum' >> /home/${USER}/.bashrc

# Copy minimal Erlang installation
COPY --from=erlang-builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/escript

# Copy essential scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
# Stage 1: Build a minimal Erlang/OTP from source
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

# Build a minimal Erlang/OTP
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
    && rm -rf otp_src_26.2.5.2/

# Stage 2: The final image
FROM semaphoreci/agent:v2.3.0

# Set up user and timezone
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore

# Install essential runtime dependencies and clean up apt cache in a single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    libssl1.1 \
    libncurses5 \
    libtinfo5 \
    zlib1g && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Copy minimal Erlang installation
COPY --from=erlang-builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/escript

# Download, install, and clean AWS CLI, Semaphore CLI, and Toolbox in a single layer
RUN mkdir -p /tmp/downloads && \
    # Download AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/downloads/awscliv2.zip" && \
    unzip /tmp/downloads/awscliv2.zip -d /tmp/downloads/ && \
    /tmp/downloads/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin && \
    rm -rf /tmp/downloads/aws /usr/local/aws-cli/v2/*/dist/awscli/examples /usr/local/aws-cli/v2/*/dist/awscli/topics && \
    find /usr/local/aws-cli -name "*.pyc" -delete && \
    # Download and install Semaphore CLI
    curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/sem && \
    # Download and install minimal Toolbox
    mkdir -p /home/${USER}/.toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /home/${USER}/.toolbox --strip-components=1 && \
    find /home/${USER}/.toolbox -type f ! -name "cache" ! -name "artifact" ! -name "retry" ! -name "libcheckout" ! -name "libchecksum" ! -name "install-toolbox" -delete && \
    # Final cleanup of temp downloads
    rm -rf /tmp/downloads /tmp/* /var/tmp/*

# Setup user environment
RUN chown -R ${USER}:${USER} /home/${USER}/.toolbox && \
    ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache && \
    ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact && \
    ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry && \
    echo '. /home/semaphore/.toolbox/libcheckout' >> /home/${USER}/.bashrc && \
    echo '. /home/semaphore/.toolbox/libchecksum' >> /home/${USER}/.bashrc && \
    mkdir -p /opt/semaphore && \
    chown -R ${USER}:${USER} /opt/semaphore /home/${USER}

# Copy essential scripts
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh && \
    chown ${USER}:${USER} /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Final cleanup
RUN find /usr/local -name "*.a" -delete -o -name "*.la" -delete

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
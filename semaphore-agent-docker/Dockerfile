# Build stage for Erlang/OTP
FROM semaphoreci/agent:v2.3.0 AS erlang-builder
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
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

# Build Erlang/OTP with minimal features and cleanup
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
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
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/ \
    && find /usr/local/lib/erlang -name "*.beam" -exec strip --strip-debug {} \; 2>/dev/null || true \
    && find /usr/local/lib/erlang -name "*.so" -exec strip {} \; 2>/dev/null || true \
    && rm -rf /usr/local/lib/erlang/lib/*/examples \
    && rm -rf /usr/local/lib/erlang/lib/*/doc \
    && rm -rf /usr/local/lib/erlang/lib/*/src

# Download stage for external tools
FROM alpine:latest AS downloader
RUN apk add --no-cache curl tar unzip

# Download and extract AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && rm awscliv2.zip

# Download Semaphore CLI
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz

# Download Toolbox
RUN mkdir -p /toolbox \
    && curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1

# Final runtime stage - keep original base
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

# Copy only essential Erlang/OTP components
COPY --from=erlang-builder /usr/local/lib/erlang/bin /usr/local/lib/erlang/bin
COPY --from=erlang-builder /usr/local/lib/erlang/erts-* /usr/local/lib/erlang/erts-13.2.2.3
COPY --from=erlang-builder /usr/local/lib/erlang/lib/kernel-* /usr/local/lib/erlang/lib/kernel-9.2.3
COPY --from=erlang-builder /usr/local/lib/erlang/lib/stdlib-* /usr/local/lib/erlang/lib/stdlib-5.2.3
COPY --from=erlang-builder /usr/local/lib/erlang/lib/sasl-* /usr/local/lib/erlang/lib/sasl-4.2.1
COPY --from=erlang-builder /usr/local/lib/erlang/lib/crypto-* /usr/local/lib/erlang/lib/crypto-5.4.1
COPY --from=erlang-builder /usr/local/lib/erlang/lib/ssl-* /usr/local/lib/erlang/lib/ssl-11.2.2
COPY --from=erlang-builder /usr/local/lib/erlang/lib/public_key-* /usr/local/lib/erlang/lib/public_key-1.15.1
COPY --from=erlang-builder /usr/local/lib/erlang/lib/asn1-* /usr/local/lib/erlang/lib/asn1-5.2.1
COPY --from=erlang-builder /usr/local/lib/erlang/releases /usr/local/lib/erlang/releases

# Create essential Erlang symlinks
RUN ln -sf /usr/local/lib/erlang/bin/erl /usr/local/bin/erl \
    && ln -sf /usr/local/lib/erlang/bin/erlc /usr/local/bin/erlc \
    && ln -sf /usr/local/lib/erlang/bin/escript /usr/local/bin/escript

# Install AWS CLI (minimal installation)
COPY --from=downloader /aws /tmp/aws
RUN /tmp/aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin \
    && rm -rf /tmp/aws \
    && rm -rf /usr/local/aws-cli/v2/*/dist/awscli/examples

# Copy Semaphore CLI
COPY --from=downloader /sem /usr/local/bin/sem
RUN chmod +x /usr/local/bin/sem

# Install Toolbox with minimal setup
COPY --from=downloader /toolbox /root/.toolbox
RUN bash /root/.toolbox/install-toolbox \
    && mkdir -p /home/${USER}/.toolbox \
    && cp -r /root/.toolbox/* /home/${USER}/.toolbox/ \
    && chown -R ${USER}:${USER} /home/${USER}/.toolbox \
    && rm -rf /root/.toolbox

# Create minimal tool symlinks
RUN ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache \
    && ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact \
    && ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry

# Setup user environment
RUN echo '. /home/semaphore/.toolbox/libcheckout' >> /home/${USER}/.bashrc \
    && echo '. /home/semaphore/.toolbox/libchecksum' >> /home/${USER}/.bashrc \
    && chown ${USER}:${USER} /home/${USER}/.bashrc

# Final Configuration
RUN mkdir -p /opt/semaphore \
    && chown ${USER}:${USER} /opt/semaphore

COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown \
    && chmod +x /opt/semaphore/entrypoint.sh \
    && chown ${USER}:${USER} /opt/semaphore/shutdown \
    && chown ${USER}:${USER} /opt/semaphore/entrypoint.sh

# Final cleanup
RUN rm -rf /tmp/* /var/tmp/* /var/log/* /var/cache/* /usr/share/doc/* /usr/share/man/*

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
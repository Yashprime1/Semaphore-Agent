# Stage 1: Build minimal Erlang from source
FROM alpine:3.18 AS erlang-builder

RUN apk add --no-cache --virtual .build-deps \
        build-base curl autoconf ncurses-dev openssl-dev zlib-dev perl \
    && curl -fsSL https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
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
    && apk del .build-deps \
    && strip --strip-unneeded /opt/erlang/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /opt/erlang -name "*.so" -exec strip --strip-unneeded {} \; 2>/dev/null || true \
    && find /opt/erlang -type d -name "src" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -name "*.beam" ! -path "*/ebin/*" -delete 2>/dev/null || true

# Stage 2: Get AWS CLI (minimal pip version)
FROM python:3.11-alpine AS aws-builder
RUN pip install --no-cache-dir --no-deps awscli==1.32.106 \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/local -name "*.pyo" -delete 2>/dev/null || true \
    && rm -rf /root/.cache /usr/local/lib/python3.11/site-packages/pip*

# Stage 3: Get Semaphore tools
FROM alpine:3.18 AS tools-builder
RUN apk add --no-cache curl \
    && curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && strip --strip-unneeded sem 2>/dev/null || true \
    && mkdir -p /toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 \
    && find /toolbox -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true

# Stage 4: Extract the Semaphore agent
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

# Stage 5: Final optimized image using distroless-like approach
FROM ubuntu:22.04

# Build args for better caching
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC

ENV USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/opt/erlang/bin:${PATH}"
ENV BASH_ENV="${HOME}/.bashrc"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

# Create user first for better layer caching
RUN groupadd -g 1000 ${USER} \
    && useradd -u 1000 -g ${USER} -m -s /bin/bash ${USER}

# Install packages and clean up in a single optimized layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        curl \
        jq \
        python3-minimal \
        python3-distutils \
        libc6 \
        libssl3 \
        libncurses6 \
        zlib1g \
    && apt-get autoremove -y \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /usr/share/pixmaps \
        /usr/share/zoneinfo \
        /usr/share/bug \
        /usr/share/lintian \
        /var/log/* \
        /usr/lib/systemd \
        /lib/systemd \
        /var/lib/systemd

# Copy binaries and set permissions in optimal order
COPY --from=agent-extractor --chown=root:root /opt/semaphore/agent /opt/semaphore/agent
COPY --from=tools-builder --chown=root:root /sem /usr/local/bin/sem
COPY --from=erlang-builder --chown=root:root /opt/erlang /opt/erlang
COPY --from=aws-builder --chown=root:root /usr/local/bin/aws /usr/local/bin/aws
COPY --from=aws-builder --chown=root:root /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Set up toolbox using your working approach
COPY --from=tools-builder /toolbox /root/.toolbox
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
    && ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results

# Set permissions
RUN chmod +x /opt/semaphore/agent /usr/local/bin/sem \
    && mkdir -p /opt/semaphore \
    && chown -R ${USER}:${USER} /opt/semaphore

# Copy scripts with proper ownership
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Final aggressive cleanup in a single layer
RUN find /usr -name "*.a" -delete 2>/dev/null || true \
    && find /usr -name "*.la" -delete 2>/dev/null || true \
    && find /usr -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /usr/include 2>/dev/null || true \
    && rm -rf /root/.toolbox

# Switch to non-root user
USER ${USER}
WORKDIR ${HOME}

# Health check for better container management
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /opt/semaphore/agent --version > /dev/null || exit 1

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
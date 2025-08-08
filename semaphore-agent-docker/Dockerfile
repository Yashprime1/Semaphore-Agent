#####################
# 1. Build Stage     #
#####################
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Install minimal build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        autoconf \
        libncurses5-dev \
        libssl-dev \
        zlib1g-dev \
        perl \
        ca-certificates \
        unzip \
        gnupg \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Build Erlang with ultra-minimal configuration
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
        --disable-dynamic-ssl-libs \
        --disable-shared \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/ \
    && strip --strip-unneeded /opt/erlang/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /opt/erlang -name "*.so" -exec strip --strip-unneeded {} \; 2>/dev/null || true \
    && find /opt/erlang -type d -name "src" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -name "*.beam" ! -path "*/ebin/*" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.a" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.la" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.txt" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.md" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.html" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.erl" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.hrl" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.app.src" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.appup.src" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.rel.src" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.script.src" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.config.src" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.mk" -delete 2>/dev/null || true \
    && find /opt/erlang -name "Makefile*" -delete 2>/dev/null || true \
    && find /opt/erlang -name "configure*" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.in" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.ac" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.am" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.m4" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.sh" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.bat" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.cmd" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.pl" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.py" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.rb" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.js" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.css" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.xml" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.json" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.yml" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.yaml" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.example" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.sample" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.template" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.orig" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.bak" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.tmp" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.swp" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*.swo" -delete 2>/dev/null || true \
    && find /opt/erlang -name "*~" -delete 2>/dev/null || true \
    && find /opt/erlang -name ".DS_Store" -delete 2>/dev/null || true \
    && find /opt/erlang -name "Thumbs.db" -delete 2>/dev/null || true

# Download and optimize Semaphore CLI and Toolbox
RUN curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && strip --strip-unneeded sem 2>/dev/null || true \
    && mkdir -p /toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 \
    && find /toolbox -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true \
    && find /toolbox -name "*.txt" -delete 2>/dev/null || true \
    && find /toolbox -name "*.md" -delete 2>/dev/null || true \
    && find /toolbox -name "*.html" -delete 2>/dev/null || true \
    && find /toolbox -name "*.css" -delete 2>/dev/null || true \
    && find /toolbox -name "*.js" -delete 2>/dev/null || true \
    && find /toolbox -name "*.xml" -delete 2>/dev/null || true \
    && find /toolbox -name "*.json" -delete 2>/dev/null || true \
    && find /toolbox -name "*.yml" -delete 2>/dev/null || true \
    && find /toolbox -name "*.yaml" -delete 2>/dev/null || true

# Install Python 3.13 with full shared library support
RUN curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get\&search=0xBA6932366A755776 | \
        gpg --dearmor -o /usr/share/keyrings/deadsnakes-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/deadsnakes-archive-keyring.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble main" \
        > /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.13 \
        python3.13-minimal \
        python3.13-dev \
        libpython3.13 \
        libpython3.13-minimal \
        libpython3.13-stdlib \
        libpython3.13-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3.13 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.13 /usr/bin/python \
    && find /usr/lib/python3.13 -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.txt" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.md" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.html" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.css" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.js" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.xml" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.json" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.yml" -delete 2>/dev/null || true \
    && find /usr/lib/python3.13 -name "*.yaml" -delete 2>/dev/null || true

# Install AWS CLI with aggressive cleanup
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf awscliv2.zip aws \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/docs 2>/dev/null || true \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/examples 2>/dev/null || true \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/tests 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.txt" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.md" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.html" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.css" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.js" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.xml" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.json" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.yml" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "*.yaml" -delete 2>/dev/null || true

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

# Install only essential runtime dependencies with correct Python 3.12 packages
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
        procps \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man /usr/share/locale \
    && rm -rf /var/cache/apt /var/lib/apt/lists/* \
    && rm -rf /usr/share/lintian /usr/share/bug \
    && rm -rf /usr/share/groff /usr/share/info \
    && rm -rf /usr/share/linda /usr/share/locale \
    && rm -rf /usr/share/zoneinfo /usr/share/calendar

# Copy optimized binaries from builder stage
COPY --from=builder --chown=root:root /opt/erlang /opt/erlang
COPY --from=builder --chown=root:root /sem /usr/local/bin/sem
COPY --from=builder --chown=root:root /toolbox /root/.toolbox
COPY --from=builder --chown=root:root /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder --chown=root:root /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder --chown=root:root /usr/local/bin/aws_completer /usr/local/bin/aws_completer

# Copy Python 3.13 from builder stage with all required libraries
COPY --from=builder --chown=root:root /usr/bin/python3.13 /usr/bin/python3.13
COPY --from=builder --chown=root:root /usr/lib/python3.13 /usr/lib/python3.13
COPY --from=builder --chown=root:root /usr/lib/x86_64-linux-gnu/libpython3.13.so* /usr/lib/x86_64-linux-gnu/
COPY --from=builder --chown=root:root /usr/include/python3.13 /usr/include/python3.13

# Create Python symlinks
RUN ln -sf /usr/bin/python3.13 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.13 /usr/bin/python

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

# Ultra-aggressive final cleanup
RUN find /usr -name "*.a" -delete 2>/dev/null || true \
    && find /usr -name "*.la" -delete 2>/dev/null || true \
    && find /usr -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr -name "*.txt" -delete 2>/dev/null || true \
    && find /usr -name "*.md" -delete 2>/dev/null || true \
    && find /usr -name "*.html" -delete 2>/dev/null || true \
    && find /usr -name "*.css" -delete 2>/dev/null || true \
    && find /usr -name "*.js" -delete 2>/dev/null || true \
    && find /usr -name "*.xml" -delete 2>/dev/null || true \
    && find /usr -name "*.json" -delete 2>/dev/null || true \
    && find /usr -name "*.yml" -delete 2>/dev/null || true \
    && find /usr -name "*.yaml" -delete 2>/dev/null || true \
    && find /usr -name "*.example" -delete 2>/dev/null || true \
    && find /usr -name "*.sample" -delete 2>/dev/null || true \
    && find /usr -name "*.template" -delete 2>/dev/null || true \
    && find /usr -name "*.orig" -delete 2>/dev/null || true \
    && find /usr -name "*.bak" -delete 2>/dev/null || true \
    && find /usr -name "*.tmp" -delete 2>/dev/null || true \
    && find /usr -name "*.swp" -delete 2>/dev/null || true \
    && find /usr -name "*.swo" -delete 2>/dev/null || true \
    && find /usr -name "*~" -delete 2>/dev/null || true \
    && find /usr -name ".DS_Store" -delete 2>/dev/null || true \
    && find /usr -name "Thumbs.db" -delete 2>/dev/null || true \
    && rm -rf /root/.toolbox \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/docs 2>/dev/null || true \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/examples 2>/dev/null || true \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/tests 2>/dev/null || true \
    && rm -rf /usr/share/locale \
    && rm -rf /usr/share/doc \
    && rm -rf /usr/share/man \
    && rm -rf /usr/share/info \
    && rm -rf /usr/share/lintian \
    && rm -rf /usr/share/bug \
    && rm -rf /usr/share/groff \
    && rm -rf /usr/share/linda \
    && rm -rf /usr/share/zoneinfo \
    && rm -rf /usr/share/calendar \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /var/cache/* \
    && rm -rf /var/lib/apt/lists/*

USER ${USER}
WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
# Multi-stage build for ultra-minimal semaphore agent image
FROM ubuntu:24.04 AS base

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential packages and Erlang from Ubuntu repositories
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg \
    lsb-release \
    && curl -fsSL https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb -o erlang-solutions_2.0_all.deb \
    && dpkg -i erlang-solutions_2.0_all.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    jq \
    unzip \
    # Erlang from Ubuntu repos (much smaller than building from source)
    erlang \
    erlang-crypto \
    erlang-syntax-tools \
    erlang-parsetools \
    erlang-inets \
    erlang-ssl \
    erlang-public-key \
    erlang-asn1 \
    # AWS CLI dependencies
    python3 \
    python3-pip \
    # Additional runtime dependencies
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
    && apt-get remove -y software-properties-common gnupg lsb-release \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f erlang-solutions_2.0_all.deb

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf awscliv2.zip aws

# Install Semaphore CLI
RUN curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && mv sem /usr/local/bin/sem \
    && chmod +x /usr/local/bin/sem

# Install Semaphore Toolbox
RUN mkdir -p /opt/toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /opt/toolbox --strip-components=1 \
    && chmod +x /opt/toolbox/*

# Extract agent from semaphoreci/agent image
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

# Final stage - create minimal runtime image
FROM base AS final

# Create semaphore user
RUN groupadd -g 1000 semaphore \
    && useradd -u 1000 -g semaphore -m -s /bin/bash semaphore

# Set up environment
ENV USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/usr/local/bin:/usr/local/aws-cli/v2/current/bin:${PATH}"
ENV BASH_ENV="${HOME}/.bashrc"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

# Copy agent from extractor stage
COPY --from=agent-extractor --chown=root:root /opt/semaphore/agent /opt/semaphore/agent

# Copy toolbox to user directory and set up symlinks
RUN mkdir -p ${HOME}/.toolbox \
    && cp -r /opt/toolbox/* ${HOME}/.toolbox/ \
    && chown -R ${USER}:${USER} ${HOME}/.toolbox \
    && chmod +x ${HOME}/.toolbox/* \
    && echo '. /home/semaphore/.toolbox/libcheckout' >> ${HOME}/.bashrc \
    && echo '. /home/semaphore/.toolbox/libchecksum' >> ${HOME}/.bashrc \
    && chown ${USER}:${USER} ${HOME}/.bashrc \
    && ln -sf ${HOME}/.toolbox/cache /usr/local/bin/cache \
    && ln -sf ${HOME}/.toolbox/artifact /usr/local/bin/artifact \
    && ln -sf ${HOME}/.toolbox/sem-context /usr/local/bin/sem-context \
    && ln -sf ${HOME}/.toolbox/retry /usr/local/bin/retry \
    && ln -sf ${HOME}/.toolbox/test-results /usr/local/bin/test-results

# Copy entrypoint and shutdown scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/agent /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Aggressive cleanup to minimize image size
RUN rm -rf /opt/toolbox \
    && find /usr -name "*.a" -delete 2>/dev/null || true \
    && find /usr -name "*.la" -delete 2>/dev/null || true \
    && find /usr -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/docs 2>/dev/null || true \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/data 2>/dev/null || true \
    && find /usr/lib/python* -name "test" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/lib/python* -name "tests" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/lib/python* -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr/lib/python* -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

USER ${USER}
WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
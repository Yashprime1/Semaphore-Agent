# Multi-stage build for ultra-minimal semaphore agent image

# Extract agent from semaphoreci/agent image
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

# Final stage - use debian slim for smaller base image
FROM debian:bookworm-slim AS final

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential packages in a single RUN command to reduce layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    jq \
    unzip \
    erlang \
    erlang-crypto \
    erlang-syntax-tools \
    erlang-parsetools \
    erlang-inets \
    erlang-ssl \
    erlang-public-key \
    erlang-asn1 \
    python3 \
    python3-pip \
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
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/locale/* \
    && rm -rf /usr/share/info/* \
    && rm -rf /usr/share/groff/* \
    && rm -rf /usr/share/lintian/* \
    && rm -rf /usr/share/common-licenses/*

# Install AWS CLI v2 and Semaphore CLI in a single layer with aggressive cleanup
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf awscliv2.zip aws \
    && curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && mv sem /usr/local/bin/sem \
    && chmod +x /usr/local/bin/sem \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/docs \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/examples \
    && find /usr/local/aws-cli -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr/local/aws-cli -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Install Semaphore Toolbox and set up user in single layer
RUN mkdir -p /opt/toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /opt/toolbox --strip-components=1 \
    && chmod +x /opt/toolbox/* \
    && groupadd -g 2000 semaphore \
    && useradd -u 2000 -g semaphore -m -s /bin/bash semaphore

# Copy agent from extractor stage
COPY --from=agent-extractor --chown=root:root /opt/semaphore/agent /opt/semaphore/agent

# Set up environment
ENV USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/usr/local/bin:/usr/local/aws-cli/v2/current/bin:${PATH}"
ENV BASH_ENV="${HOME}/.bashrc"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

# Copy entrypoint and shutdown scripts
COPY --chown=root:root shutdown.sh /opt/semaphore/shutdown
COPY --chown=root:root entrypoint.sh /opt/semaphore/entrypoint.sh

# Set up toolbox and scripts in single layer
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
    && ln -sf ${HOME}/.toolbox/test-results /usr/local/bin/test-results \
    && chmod +x /opt/semaphore/agent /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh \
    && chown -R ${USER}:${USER} /opt/semaphore

# Final cleanup to minimize image size
RUN rm -rf /opt/toolbox \
    && find /usr -name "*.a" -delete 2>/dev/null || true \
    && find /usr -name "*.la" -delete 2>/dev/null || true \
    && find /usr -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/lib/python* -name "test" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/lib/python* -name "tests" -type d -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/lib/python* -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr/lib/python* -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]

# ---------------------------
# Stage 1 - Extract Semaphore Agent
# ---------------------------
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

# ---------------------------
# Stage 2 - Build final minimal image
# ---------------------------
FROM debian:bookworm-slim AS final

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    USER=semaphore \
    HOME=/home/semaphore \
    PATH="/usr/local/bin:/usr/local/aws-cli/v2/current/bin:$PATH" \
    BASH_ENV="/home/semaphore/.bashrc" \
    SEMAPHORE_TOOLBOX_DIR="/home/semaphore/.toolbox"

# ---------------------------
# Install dependencies
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git openssh-client jq unzip \
    erlang erlang-ssl erlang-public-key erlang-asn1 \
    python3 python3-pip \
    libc6 libssl3 libncurses6 zlib1g tzdata libffi8 libexpat1 \
    libbz2-1.0 liblzma5 libreadline8 libsqlite3-0 libuuid1 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
            /usr/share/doc/* /usr/share/man/* \
            /usr/share/locale/* /usr/share/info/* \
            /usr/share/groff/* /usr/share/lintian/* \
            /usr/share/common-licenses/*

# ---------------------------
# Install AWS CLI v2 + Semaphore CLI
# ---------------------------
RUN curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf awscliv2.zip aws \
    && curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz \
    | tar -xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/sem \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/{docs,examples} \
    && find /usr/local/aws-cli -type f -name "*.pyc" -delete \
    && find /usr/local/aws-cli -type d -name __pycache__ -exec rm -rf {} +

# ---------------------------
# Install Semaphore Toolbox + user
# ---------------------------
RUN groupadd -g 2000 semaphore \
    && useradd -u 2000 -g semaphore -m -s /bin/bash semaphore \
    && mkdir -p /opt/toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar \
    | tar -x -C /opt/toolbox --strip-components=1 \
    && chmod +x /opt/toolbox/* \
    && mkdir -p /home/semaphore/.toolbox \
    && cp -r /opt/toolbox/* /home/semaphore/.toolbox/ \
    && chown -R semaphore:semaphore /home/semaphore/.toolbox /home/semaphore/.bashrc \
    && echo '. ~/.toolbox/libcheckout' >> /home/semaphore/.bashrc \
    && echo '. ~/.toolbox/libchecksum' >> /home/semaphore/.bashrc \
    && ln -s ~/.toolbox/cache /usr/local/bin/cache \
    && ln -s ~/.toolbox/artifact /usr/local/bin/artifact \
    && ln -s ~/.toolbox/sem-context /usr/local/bin/sem-context \
    && ln -s ~/.toolbox/retry /usr/local/bin/retry \
    && ln -s ~/.toolbox/test-results /usr/local/bin/test-results

# ---------------------------
# Copy agent + scripts
# ---------------------------
COPY --from=agent-extractor /opt/semaphore/agent /opt/semaphore/agent
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh

RUN chmod +x /opt/semaphore/{agent,shutdown,entrypoint.sh} \
    && chown -R semaphore:semaphore /opt/semaphore

# ---------------------------
# Final Cleanup
# ---------------------------
RUN rm -rf /opt/toolbox /tmp/* /var/tmp/* \
    && find /usr -type f \( -name "*.a" -o -name "*.la" \) -delete \
    && find /usr -type f -name "*.pyc" -delete \
    && find /usr -type d -name __pycache__ -exec rm -rf {} + \
    && find /usr/lib/python* -type d \( -name test -o -name tests \) -exec rm -rf {} +

USER semaphore
WORKDIR /home/semaphore
ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]

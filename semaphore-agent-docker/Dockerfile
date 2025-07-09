# Multi-stage Dockerfile for Semaphore CI Agent
# Stage 1: Build stage - contains all build tools and dependencies
FROM semaphoreci/agent:v2.3.0 AS builder

# Switch to root user for package installation and builds
USER root

# Set timezone and frontend non-interactively
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    unzip \
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
    openjdk-11-jdk \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Install Semaphore CLI tools
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && mv sem /usr/local/bin/ \
    && chmod +x /usr/local/bin/sem

# Build and install Erlang
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/

# Install Semaphore Toolbox
RUN mkdir -p ~/.toolbox \
    && curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C ~/.toolbox --strip-components=1 \
    && bash ~/.toolbox/install-toolbox || true \
    && ls -la ~/.toolbox/ \
    && ls -la /usr/local/bin/ \
    && echo "Manually installing toolbox binaries..." \
    && find ~/.toolbox -name "cache" -type f -executable -exec cp {} /usr/local/bin/cache \; \
    && find ~/.toolbox -name "artifacts" -type f -executable -exec cp {} /usr/local/bin/artifacts \; \
    && find ~/.toolbox -name "spc" -type f -executable -exec cp {} /usr/local/bin/spc \; \
    && find ~/.toolbox -name "test-results" -type f -executable -exec cp {} /usr/local/bin/test-results \; \
    && find ~/.toolbox -name "retry" -type f -executable -exec cp {} /usr/local/bin/retry \; \
    && find ~/.toolbox -name "sem-context" -type f -executable -exec cp {} /usr/local/bin/sem-context \; \
    && chmod +x /usr/local/bin/{cache,artifacts,spc,test-results,retry,sem-context} || true

# Stage 2: Runtime stage - minimal image with only runtime dependencies
FROM semaphoreci/agent:v2.3.0 AS runtime

# Switch to root user for package installation
USER root

# Set timezone and frontend non-interactively
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    libncurses5 \
    libssl1.1 \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy built artifacts from builder stage
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/bin/sem /usr/local/bin/sem
COPY --from=builder /usr/local/lib/erlang/ /usr/local/lib/erlang/
COPY --from=builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=builder /usr/local/bin/escript /usr/local/bin/escript
COPY --from=builder /root/.toolbox/ /root/.toolbox/

# Copy Semaphore toolbox binaries if they exist
COPY --from=builder /usr/local/bin/cache /usr/local/bin/cache || true
COPY --from=builder /usr/local/bin/artifacts /usr/local/bin/artifacts || true
COPY --from=builder /usr/local/bin/test-results /usr/local/bin/test-results || true
COPY --from=builder /usr/local/bin/retry /usr/local/bin/retry || true
COPY --from=builder /usr/local/bin/spc /usr/local/bin/spc || true
COPY --from=builder /usr/local/bin/sem-context /usr/local/bin/sem-context || true

# Ensure PATH includes /usr/local/bin
ENV PATH="/usr/local/bin:${PATH}"

# Create necessary directories and set permissions
RUN mkdir -p /opt/semaphore

# Copy application scripts
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh

# Set executable permissions
RUN chmod +x /opt/semaphore/shutdown \
    && chmod +x /opt/semaphore/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
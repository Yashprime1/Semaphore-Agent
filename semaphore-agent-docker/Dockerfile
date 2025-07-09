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
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-28.0.1/otp_src_28.0.1.tar.gz | tar -xz \
    && cd otp_src_28.0.1/ \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf otp_src_28.0.1/

# Install Semaphore Toolbox
RUN mkdir -p ~/.toolbox \
    && curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C ~/.toolbox --strip-components=1 \
    && bash ~/.toolbox/install-toolbox

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
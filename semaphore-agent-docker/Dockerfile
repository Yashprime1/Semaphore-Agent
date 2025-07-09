FROM semaphoreci/agent:v2.3.0

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
    && bash ~/.toolbox/install-toolbox

# Create necessary directories and set permissions
RUN mkdir -p /opt/semaphore

# Copy application scripts
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh

# Set executable permissions
RUN chmod +x /opt/semaphore/shutdown \
    && chmod +x /opt/semaphore/entrypoint.sh

RUN chown semaphore:semaphore /opt/semaphore/shutdown \
    && chown semaphore:semaphore /opt/semaphore/entrypoint.sh
USER semaphore
# Set the entrypoint
ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
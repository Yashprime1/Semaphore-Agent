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

# Build Erlang/OTP
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure --disable-debug --disable-hipe --disable-javac --without-javac \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/

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

# Final runtime stage
FROM semaphoreci/agent:v2.3.0
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore

# First try to install packages, with fallback for different package names
RUN apt-get update && \
    (apt-get install -y --no-install-recommends \
        curl \
        unzip \
        jq \
        git \
        libncurses5 \
        libssl1.1 \
        openssh-client \
        ca-certificates \
        libwxgtk3.0-gtk3-0 \
        libgl1-mesa-glx \
        libglu1-mesa \
        libpng16-16 \
        libssh-4 \
        unixodbc \
        libxml2-utils || \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        jq \
        git \
        libncurses5 \
        libssl1.1 \
        openssh-client \
        ca-certificates \
        libwxbase3.0-0v5 \
        libwxgtk3.0-0v5 \
        libgl1-mesa-glx \
        libglu1-mesa \
        libpng16-16 \
        libssh-gcrypt-4 \
        unixodbc \
        libxml2-utils) \
    && rm -rf /var/lib/apt/lists/*

# Copy Erlang/OTP from builder stage
COPY --from=erlang-builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/escript
COPY --from=erlang-builder /usr/local/bin/run_erl /usr/local/bin/run_erl
COPY --from=erlang-builder /usr/local/bin/to_erl /usr/local/bin/to_erl
COPY --from=erlang-builder /usr/local/bin/dialyzer /usr/local/bin/dialyzer
COPY --from=erlang-builder /usr/local/bin/typer /usr/local/bin/typer
COPY --from=erlang-builder /usr/local/bin/ct_run /usr/local/bin/ct_run

# Install AWS CLI from downloader stage
COPY --from=downloader /aws /tmp/aws
RUN /tmp/aws/install && rm -rf /tmp/aws

# Copy Semaphore CLI from downloader stage
COPY --from=downloader /sem /usr/local/bin/sem
RUN chmod +x /usr/local/bin/sem

# Copy and install Toolbox from downloader stage
COPY --from=downloader /toolbox /home/${USER}/.toolbox
RUN bash /home/${USER}/.toolbox/install-toolbox

# Setting up User and Tools
RUN echo '. /home/semaphore/.toolbox/libcheckout' >> /home/${USER}/.bashrc \
    && echo '. /home/semaphore/.toolbox/libchecksum' >> /home/${USER}/.bashrc \
    && chown ${USER}:${USER} /home/${USER}/.bashrc \
    && ln -sf /home/${USER}/.toolbox/cache /usr/local/bin/cache \
    && ln -sf /home/${USER}/.toolbox/artifact /usr/local/bin/artifact \
    && ln -sf /home/${USER}/.toolbox/sem-context /usr/local/bin/sem-context \
    && ln -sf /home/${USER}/.toolbox/retry /usr/local/bin/retry \
    && ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results \
    && chown -R ${USER}:${USER} /home/${USER}/.toolbox

# Final Configuration
RUN mkdir -p /opt/semaphore \
    && chown ${USER}:${USER} /opt/semaphore

COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown \
    && chmod +x /opt/semaphore/entrypoint.sh \
    && chown ${USER}:${USER} /opt/semaphore/shutdown \
    && chown ${USER}:${USER} /opt/semaphore/entrypoint.sh

# Clean up any remaining temporary files
RUN rm -rf /tmp/* /var/tmp/*

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
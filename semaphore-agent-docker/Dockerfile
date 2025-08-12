######################################
# 1️⃣ Builder Stage
######################################
FROM debian:bookworm AS builder

# Install everything needed for build + UPX
RUN apt-get update && apt-get install -y \
    build-essential curl wget git unzip zip \
    libssl-dev libncurses5-dev libncursesw5-dev \
    zlib1g-dev libffi-dev python3 python3-pip \
    upx-ucl \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------
# Install Erlang
# ---------------------------------------------------
RUN mkdir -p /opt/erlang && \
    curl -sSL https://erlang.org/download/otp_src_26.0.tar.gz | tar -xz -C /tmp && \
    cd /tmp/otp_src_26.0 && ./configure --prefix=/opt/erlang && make -j$(nproc) && make install && \
    rm -rf /tmp/otp_src_26.0

# ---------------------------------------------------
# Install AWS CLI v2
# ---------------------------------------------------
RUN curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# ---------------------------------------------------
# Install Toolbox (example)
# ---------------------------------------------------
RUN mkdir -p /toolbox && \
    echo "#!/bin/bash\necho Toolbox running" > /toolbox/tool && \
    chmod +x /toolbox/tool

# ---------------------------------------------------
# Strip binaries & harvest runtime libs
# ---------------------------------------------------
RUN mkdir -p /opt/runtime-libs && \
    BINARIES="$(find /opt/erlang/bin /usr/local/bin /toolbox -type f -executable)" && \
    echo "$BINARIES" > /tmp/bin_list.txt && \
    # Collect runtime library dependencies
    echo "$BINARIES" | while read bin; do \
        ldd "$bin" 2>/dev/null | awk '{print $3}' | grep '^/' || true; \
    done | sort -u > /tmp/libdeps.txt && \
    # Copy required libs preserving paths
    cat /tmp/libdeps.txt | while read lib; do \
        mkdir -p "/opt/runtime-libs$(dirname $lib)" && \
        cp --parents "$lib" /opt/runtime-libs/; \
    done && \
    # Strip all binaries
    echo "$BINARIES" | while read bin; do \
        strip --strip-unneeded "$bin" 2>/dev/null || true; \
    done && \
    # Compress with UPX
    echo "$BINARIES" | while read bin; do \
        upx --lzma --best "$bin" 2>/dev/null || true; \
    done && \
    echo "==== Runtime binaries ====" && cat /tmp/bin_list.txt && \
    echo "==== Runtime libs ====" && cat /tmp/libdeps.txt

FROM semaphoreci/agent:v2.3.0 AS agent-extractor
######################################
# 2️⃣ Final Runtime Stage
######################################
FROM debian:bookworm-slim AS final

ARG USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/opt/erlang/bin:/usr/local/bin:/usr/local/aws-cli/v2/current/bin:${PATH}"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

RUN groupadd -g 1001 ${USER} && \
    useradd -u 1001 -g ${USER} -m -s /bin/bash ${USER}

# Copy runtime libs + binaries
COPY --from=builder /opt/runtime-libs/ /
COPY --from=builder /opt/erlang /opt/erlang
COPY --from=builder /usr/local/bin/sem /usr/local/bin/sem
COPY --from=builder /toolbox ${HOME}/.toolbox
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/bin/aws_completer /usr/local/bin/aws_completer

# Copy Semaphore agent (replace with your own source)
COPY --######################################
# 1️⃣ Builder Stage
######################################
FROM debian:bookworm AS builder

# Install everything needed for build + UPX
RUN apt-get update && apt-get install -y \
    build-essential curl wget git unzip zip \
    libssl-dev libncurses5-dev libncursesw5-dev \
    zlib1g-dev libffi-dev python3 python3-pip \
    upx-ucl \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------
# Install Erlang
# ---------------------------------------------------
RUN mkdir -p /opt/erlang && \
    curl -sSL https://erlang.org/download/otp_src_26.0.tar.gz | tar -xz -C /tmp && \
    cd /tmp/otp_src_26.0 && ./configure --prefix=/opt/erlang && make -j$(nproc) && make install && \
    rm -rf /tmp/otp_src_26.0

# ---------------------------------------------------
# Install AWS CLI v2
# ---------------------------------------------------
RUN curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# ---------------------------------------------------
# Install Toolbox (example)
# ---------------------------------------------------
RUN mkdir -p /toolbox && \
    echo "#!/bin/bash\necho Toolbox running" > /toolbox/tool && \
    chmod +x /toolbox/tool

# ---------------------------------------------------
# Strip binaries & harvest runtime libs
# ---------------------------------------------------
RUN mkdir -p /opt/runtime-libs && \
    BINARIES="$(find /opt/erlang/bin /usr/local/bin /toolbox -type f -executable)" && \
    echo "$BINARIES" > /tmp/bin_list.txt && \
    # Collect runtime library dependencies
    echo "$BINARIES" | while read bin; do \
        ldd "$bin" 2>/dev/null | awk '{print $3}' | grep '^/' || true; \
    done | sort -u > /tmp/libdeps.txt && \
    # Copy required libs preserving paths
    cat /tmp/libdeps.txt | while read lib; do \
        mkdir -p "/opt/runtime-libs$(dirname $lib)" && \
        cp --parents "$lib" /opt/runtime-libs/; \
    done && \
    # Strip all binaries
    echo "$BINARIES" | while read bin; do \
        strip --strip-unneeded "$bin" 2>/dev/null || true; \
    done && \
    # Compress with UPX
    echo "$BINARIES" | while read bin; do \
        upx --lzma --best "$bin" 2>/dev/null || true; \
    done && \
    echo "==== Runtime binaries ====" && cat /tmp/bin_list.txt && \
    echo "==== Runtime libs ====" && cat /tmp/libdeps.txt

FROM semaphoreci/agent:v2.3.0 AS agent-extractor

######################################
# 2️⃣ Final Runtime Stage
######################################
FROM debian:bookworm-slim AS final

ARG USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/opt/erlang/bin:/usr/local/bin:/usr/local/aws-cli/v2/current/bin:${PATH}"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

RUN groupadd -g 1001 ${USER} && \
    useradd -u 1001 -g ${USER} -m -s /bin/bash ${USER}

# Copy runtime libs + binaries
COPY --from=builder /opt/runtime-libs/ /
COPY --from=builder /opt/erlang /opt/erlang
COPY --from=builder /usr/local/bin/sem /usr/local/bin/sem
COPY --from=builder /toolbox ${HOME}/.toolbox
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /usr/local/bin/aws_completer /usr/local/bin/aws_completer

# Copy Semaphore agent (replace with your own source)
COPY --from=agent-extractor /opt/semaphore/agent /opt/semaphore/agent

# Scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh \
    && chown -R ${USER}:${USER} /home/semaphore /opt/semaphore

USER ${USER}
WORKDIR ${HOME}
ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
 /opt/semaphore/agent /opt/semaphore/agent

# Scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh \
    && chown -R ${USER}:${USER} /home/semaphore /opt/semaphore

USER ${USER}
WORKDIR ${HOME}
ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]

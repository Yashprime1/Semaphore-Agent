# Stage 1: Build minimal Erlang
FROM alpine:3.18 AS erlang-builder
RUN apk add --no-cache build-base curl autoconf ncurses-dev openssl-dev zlib-dev perl

RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
    && cd otp_src_26.2.5.2/ \
    && ./configure \
        --prefix=/usr/local \
        --enable-smp-support \
        --disable-debug \
        --disable-hipe \
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
        --without-asn1 \
        --enable-shared-zlib \
    && make -j$(nproc) \
    && make install \
    && strip /usr/local/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /usr/local/lib/erlang -name "*.so" -exec strip {} \; 2>/dev/null || true \
    && rm -rf /usr/local/lib/erlang/lib/*/src \
    && rm -rf /usr/local/lib/erlang/lib/*/examples \
    && rm -rf /usr/local/lib/erlang/lib/*/doc \
    && cd .. && rm -rf otp_src_26.2.5.2/

# Stage 2: Get AWS CLI (pip version - much smaller)
FROM python:3.11-alpine AS aws-builder
RUN pip install --no-cache-dir awscli \
    && find /usr/local -name "*.pyc" -delete \
    && find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Stage 3: Get tools
FROM alpine:3.18 AS tools-builder
RUN apk add --no-cache curl tar
RUN curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz
RUN mkdir -p /toolbox && \
    curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1

# Stage 4: Extract just the agent binary from semaphoreci/agent
FROM semaphoreci/agent:v2.3.0 AS agent-extractor
# Just extract the agent binary and essential libs

# Stage 5: Final optimized image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV USER=semaphore
ENV HOME=/home/${USER}

# Create user and install minimal packages
RUN groupadd -g 1000 ${USER} \
    && useradd -u 1000 -g ${USER} -m -s /bin/bash ${USER} \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        curl \
        jq \
        python3 \
        python3-distutils \
        libc6 \
        libssl3 \
        libncurses6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* \
    && rm -rf /usr/share/doc /usr/share/man /usr/share/info /usr/share/locale /usr/share/pixmaps

# Copy the actual semaphore agent binary
COPY --from=agent-extractor /opt/semaphore/agent /opt/semaphore/agent

# Copy minimal AWS CLI (pip version)
COPY --from=aws-builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=aws-builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Copy Semaphore CLI
COPY --from=tools-builder /sem /usr/local/bin/sem
RUN chmod +x /usr/local/bin/sem

# Copy minimal Erlang installation
COPY --from=erlang-builder /usr/local/lib/erlang /usr/local/lib/erlang
COPY --from=erlang-builder /usr/local/bin/erl /usr/local/bin/erl
COPY --from=erlang-builder /usr/local/bin/erlc /usr/local/bin/erlc
COPY --from=erlang-builder /usr/local/bin/escript /usr/local/bin/escript

# Copy essential toolbox files and create minimal versions of missing ones
COPY --from=tools-builder /toolbox ${HOME}/.toolbox
RUN chown -R ${USER}:${USER} ${HOME}/.toolbox && \
    # Create missing tools as minimal scripts
    echo '#!/bin/bash\necho "cache: $*" >&2\n[ -f "${HOME}/.toolbox/cache" ] && exec "${HOME}/.toolbox/cache" "$@" || true' > /usr/local/bin/cache && \
    echo '#!/bin/bash\necho "artifact: $*" >&2\n[ -f "${HOME}/.toolbox/artifact" ] && exec "${HOME}/.toolbox/artifact" "$@" || true' > /usr/local/bin/artifact && \
    echo '#!/bin/bash\necho "retry: $*" >&2\n[ -f "${HOME}/.toolbox/retry" ] && exec "${HOME}/.toolbox/retry" "$@" || true' > /usr/local/bin/retry && \
    echo '#!/bin/bash\ncase "$1" in get) echo "${!2}";; put) export "$2"="$3";; *) echo "Usage: sem-context {get|put} <key> [value]" >&2; exit 1;; esac' > /usr/local/bin/sem-context && \
    echo '#!/bin/bash\necho "test-results: $*" >&2' > /usr/local/bin/test-results && \
    chmod +x /usr/local/bin/* && \
    # Add to bashrc
    echo '. ${HOME}/.toolbox/libcheckout 2>/dev/null || true' >> ${HOME}/.bashrc && \
    echo '. ${HOME}/.toolbox/libchecksum 2>/dev/null || true' >> ${HOME}/.bashrc && \
    chown ${USER}:${USER} ${HOME}/.bashrc && \
    mkdir -p /opt/semaphore && \
    chown ${USER}:${USER} /opt/semaphore

# Copy scripts
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Final aggressive cleanup
RUN find /usr -name "*.a" -delete 2>/dev/null || true && \
    find /usr -name "*.la" -delete 2>/dev/null || true && \
    rm -rf /usr/include/* 2>/dev/null || true && \
    rm -rf /var/log/* 2>/dev/null || true && \
    rm -rf /usr/share/zoneinfo 2>/dev/null || true && \
    rm -rf /usr/lib/systemd 2>/dev/null || true

USER ${USER}
WORKDIR ${HOME}

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
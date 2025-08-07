#####################
# 1. Build Erlang   #
#####################
FROM alpine:3.18 AS erlang-builder

RUN apk add --no-cache --virtual .build-deps \
        build-base curl autoconf ncurses-dev openssl-dev zlib-dev perl \
    && curl -fsSL https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz \
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
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf otp_src_26.2.5.2/ \
    && apk del .build-deps \
    && strip --strip-unneeded /opt/erlang/lib/erlang/erts-*/bin/* 2>/dev/null || true \
    && find /opt/erlang -name "*.so" -exec strip --strip-unneeded {} \; 2>/dev/null || true \
    && find /opt/erlang -type d -name "src" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -type d -name "doc" -exec rm -rf {} + 2>/dev/null || true \
    && find /opt/erlang -name "*.beam" ! -path "*/ebin/*" -delete 2>/dev/null || true

#####################
# 2. Build AWS CLI  #
#####################
FROM ubuntu:22.04 AS aws-builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli && \
    rm -rf awscliv2.zip aws && \
    apt-get purge -y --auto-remove curl unzip ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

##########################
# 3. Semaphore tools     #
##########################
FROM alpine:3.18 AS tools-builder

RUN apk add --no-cache curl \
    && curl -fsSL https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz \
    && strip --strip-unneeded sem 2>/dev/null || true \
    && mkdir -p /toolbox \
    && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -x -C /toolbox --strip-components=1 \
    && find /toolbox -type f -executable -exec strip --strip-unneeded {} \; 2>/dev/null || true

###############################
# 4. Semaphore Agent Artifact #
###############################
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

#######################
# 5. Final IMAGE      #
#######################
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC

# Create Semaphore user first for layer caching
ENV USER=semaphore
ENV HOME=/home/${USER}
ENV PATH="/opt/erlang/bin:/usr/local/aws-cli/v2/current:${PATH}"
ENV BASH_ENV="${HOME}/.bashrc"
ENV SEMAPHORE_TOOLBOX_DIR="${HOME}/.toolbox"

RUN groupadd -g 1000 ${USER} \
    && useradd -u 1000 -g ${USER} -m -s /bin/bash ${USER}

# Basic required tools and Python dependencies (note: lsb-release needed for deadsnakes PPA setup)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        openssh-client \
        curl \
        jq \
        gnupg \
        software-properties-common \
        lsb-release \
        unzip \
        libc6 \
        libssl3 \
        libncurses6 \
        zlib1g \
        tzdata \
    && curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get\&search=0xBA6932366A755776 | \
        gpg --dearmor -o /usr/share/keyrings/deadsnakes-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/deadsnakes-archive-keyring.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" \
        > /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends python3.13 libpython3.13-stdlib \
    && apt-get remove -y gnupg software-properties-common lsb-release unzip \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add Semaphore agent, Erlang, AWS CLI, and tools
COPY --from=agent-extractor --chown=root:root /opt/semaphore/agent /opt/semaphore/agent
COPY --from=erlang-builder --chown=root:root /opt/erlang /opt/erlang
COPY --from=tools-builder --chown=root:root /sem /usr/local/bin/sem
COPY --from=aws-builder --chown=root:root /usr/local/bin/aws /usr/local/bin/aws
COPY --from=aws-builder --chown=root:root /usr/local/bin/aws_completer /usr/local/bin/aws_completer
COPY --from=aws-builder --chown=root:root /usr/local/aws-cli /usr/local/aws-cli

# Toolbox setup
COPY --from=tools-builder /toolbox /root/.toolbox
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
    && ln -sf /home/${USER}/.toolbox/test-results /usr/local/bin/test-results

# Ensure permissions and do not strip Python or AWS CLI shared libraries!
RUN chmod +x /opt/semaphore/agent /usr/local/bin/sem \
    && mkdir -p /opt/semaphore \
    && chown -R ${USER}:${USER} /opt/semaphore \
    && ldconfig

# Add your entrypoint and shutdown scripts (these must be in your build context)
COPY --chown=${USER}:${USER} shutdown.sh /opt/semaphore/shutdown
COPY --chown=${USER}:${USER} entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh

# Final safe cleanup: do NOT remove /usr/lib or Python shared libs!
RUN find /usr -name "*.a" -delete 2>/dev/null || true \
    && find /usr -name "*.la" -delete 2>/dev/null || true \
    && find /usr -name "*.pyc" -delete 2>/dev/null || true \
    && find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf /usr/include 2>/dev/null || true \
    && rm -rf /root/.toolbox \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/data \
    && rm -rf /usr/local/aws-cli/v2/current/dist/botocore/docs \
    && rm -rf /usr/local/aws-cli/v2/current/dist/awscli/data

USER ${USER}
WORKDIR ${HOME}

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /opt/semaphore/agent --version > /dev/null || exit 1

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]

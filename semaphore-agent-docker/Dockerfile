######### Stage 1 - Build Erlang runtime #########
FROM alpine:3.19 AS erlang-builder

ARG OTP_VERSION=28.0.1

RUN apk add --no-cache --virtual .build-deps \
    build-base curl autoconf ncurses-dev openssl-dev zlib-dev perl \
 && apk add --no-cache \
    ncurses-libs libstdc++ libgcc \
 && curl -fsSL https://github.com/erlang/otp/releases/download/OTP-${OTP_VERSION}/otp_src_${OTP_VERSION}.tar.gz \
    | tar -xz \
 && cd otp_src_${OTP_VERSION} \
 && ./configure \
    --prefix=/opt/erlang \
    --enable-smp-support \
    --disable-debug \
    --disable-hipe \
    --disable-sctp \
    --disable-observer \
    --enable-shared-zlib --enable-static-drivers \
 && make -j"$(nproc)" && make install \
 && cd .. && rm -rf otp_src_${OTP_VERSION} \
 && apk del .build-deps \
 && rm -rf /opt/erlang/lib/erlang/lib/*/src \
           /opt/erlang/lib/erlang/lib/*/doc \
           /opt/erlang/lib/erlang/lib/*/examples \
 && echo "Verifying Erlang installation in builder stage..." \
 && ls -la /opt/erlang/bin/ \
 && /opt/erlang/bin/erl -eval "erlang:halt()." -noshell \
 && echo "Testing escript with a simple script..." \
 && echo 'io:format("escript test~n").' > /tmp/test.escript \
 && /opt/erlang/bin/escript /tmp/test.escript

######### Stage 2 - Build Semaphore tools #########
FROM alpine:3.19 AS tools-builder

ARG SEM_CLI_VERSION=0.32.0
ARG TOOLBOX_VERSION=1.28.0

RUN apk add --no-cache curl \
 && curl -fsSL https://github.com/semaphoreci/cli/releases/download/v${SEM_CLI_VERSION}/sem_Linux_x86_64.tar.gz \
    | tar -xz \
 && mkdir -p /toolbox \
 && curl -fsSL https://github.com/semaphoreci/toolbox/releases/download/v${TOOLBOX_VERSION}/self-hosted-linux.tar \
    | tar -x -C /toolbox --strip-components=1 \
 && find /toolbox -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true

######### Stage 3 - Extract Agent  #########
FROM semaphoreci/agent:v2.3.0 AS agent-extractor

######### Stage 4 - Final Image: Ubuntu 24.04 #########
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC

ENV USER=semaphore \
    HOME=/home/semaphore \
    PATH="/opt/erlang/bin:/usr/local/bin:/usr/local/aws-cli/v2/current/bin:${PATH}" \
    BASH_ENV="/home/semaphore/.bashrc" \
    SEMAPHORE_TOOLBOX_DIR="/home/semaphore/.toolbox" \
    ERLANG_HOME="/opt/erlang"

RUN groupadd -g 3000 $USER \
 && useradd -u 3000 -g $USER -m -s /bin/bash $USER \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git jq openssh-client python3 tzdata \
 && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip \
 && apt-get install -y unzip \
 && unzip awscliv2.zip \
 && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
 && rm -rf awscliv2.zip aws \
 && apt-get purge -y unzip \
 && apt-get autoremove -y && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/locales/*

# Copy binaries & tools
COPY --from=agent-extractor /opt/semaphore/agent /opt/semaphore/agent
COPY --from=erlang-builder /opt/erlang /opt/erlang
COPY --from=tools-builder /sem /usr/local/bin/sem
COPY --from=tools-builder /toolbox /home/semaphore/.toolbox

# Debug: Check what was copied
RUN echo "Checking what was copied from erlang-builder stage..." \
 && ls -la /opt/erlang/bin/ || echo "Directory not found" \
 && echo "Checking if escript exists..." \
 && ls -la /opt/erlang/bin/escript || echo "escript not found"

# Verify Erlang installation and escript availability
RUN /opt/erlang/bin/erl -eval "erlang:halt()." -noshell \
 && echo "Testing escript with a simple script..." \
 && echo 'io:format("escript test~n").' > /tmp/test.escript \
 && /opt/erlang/bin/escript /tmp/test.escript

# Install additional Semaphore CI tools
RUN echo "Installing additional semaphoreci tools" \
 && echo "Installing SPC (Semaphore Pipeline Compiler)..." \
 && curl -L https://github.com/semaphoreci/spc/releases/download/v1.12.1/spc_Linux_x86_64.tar.gz | tar -xz \
 && mv spc /usr/local/bin/ \
 && chmod +x /usr/local/bin/spc \
 && echo "Installing When..." \
 && curl -L https://github.com/renderedtext/when/releases/download/v1.2.1/when_otp_26 -o /usr/local/bin/when \
 && chmod +x /usr/local/bin/when \
 && echo "Testing when tool installation..." \
 && when --version

RUN chown -R $USER:$USER /home/semaphore/.toolbox \
 && chmod +x /home/semaphore/.toolbox/* \
 && echo '. /home/semaphore/.toolbox/libcheckout' >> /home/semaphore/.bashrc \
 && echo '. /home/semaphore/.toolbox/libchecksum' >> /home/semaphore/.bashrc \
 && ln -sf /home/semaphore/.toolbox/cache /usr/local/bin/cache \
 && ln -sf /home/semaphore/.toolbox/artifact /usr/local/bin/artifact \
 && ln -sf /home/semaphore/.toolbox/sem-context /usr/local/bin/sem-context \
 && ln -sf /home/semaphore/.toolbox/retry /usr/local/bin/retry \
 && ln -sf /home/semaphore/.toolbox/test-results /usr/local/bin/test-results \
 && chmod +x /opt/semaphore/agent /usr/local/bin/sem \
 && echo "Testing when tool..." \
 && when --version

COPY --chown=$USER:$USER shutdown.sh /opt/semaphore/shutdown
COPY --chown=$USER:$USER entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/shutdown /opt/semaphore/entrypoint.sh && chown -R $USER:$USER /opt/semaphore

RUN rm -rf /root/.toolbox /usr/local/aws-cli/v2/current/dist/botocore/docs \
 && find /usr -name "*.a" -delete \
 && find /usr -name "*.la" -delete \
 && find /usr -name "*.pyc" -delete \
 && find /usr -name "__pycache__" -type d -exec rm -rf {} + || true \
 && echo "Verifying escript is still available after cleanup..." \
 && echo 'io:format("escript test~n").' > /tmp/test.escript \
 && /opt/erlang/bin/escript /tmp/test.escript \
 && echo "Verifying other Erlang binaries..." \
 && /opt/erlang/bin/erl -eval "erlang:halt()." -noshell \
 && /opt/erlang/bin/erlc -help | head -1

USER $USER
WORKDIR $HOME

ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]

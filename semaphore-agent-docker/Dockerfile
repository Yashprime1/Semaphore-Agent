# Build stage - minimal Erlang
FROM alpine:3.18 AS erlang-builder
RUN apk add --no-cache build-base curl autoconf ncurses-dev openssl-dev zlib-dev perl

# Build only BEAM VM + essential libraries
RUN curl -L https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz | tar -xz && \
    cd otp_src_26.2.5.2/ && \
    ./configure --prefix=/opt/erl --enable-smp-support --disable-debug \
        --disable-hipe --disable-javac --enable-static-nifs \
        --without-javac --without-wx --without-observer --without-debugger \
        --without-et --without-gs --without-ic --without-orber \
        --without-diameter --without-eldap --without-erl_docgen \
        --without-ftp --without-jinterface --without-megaco --without-odbc \
        --without-reltool --without-ssh --without-tftp --without-typer \
        --without-snmp --without-mnesia --without-eunit --without-common_test \
        --without-dialyzer --without-xmerl --without-parsetools \
        --without-syntax_tools --without-tools --without-runtime_tools \
        --without-inets --without-edoc --without-erl_interface \
    && make -j$(nproc) && make install && cd .. && rm -rf otp_src_26.2.5.2/

# Create absolute minimal Erlang runtime
RUN mkdir -p /minimal && \
    # Copy only beam.smp and essential shared libraries
    cp /opt/erl/lib/erlang/erts-*/bin/beam.smp /minimal/ && \
    cp /opt/erl/bin/erl /minimal/erl && \
    # Create minimal lib structure with only kernel+stdlib
    mkdir -p /minimal/lib && \
    cp -r /opt/erl/lib/erlang/lib/kernel-*/ebin /minimal/lib/kernel && \
    cp -r /opt/erl/lib/erlang/lib/stdlib-*/ebin /minimal/lib/stdlib && \
    # Strip everything
    strip /minimal/* 2>/dev/null || true

# Minimal tools stage
FROM alpine:3.18 AS tools
RUN apk add --no-cache curl && \
    curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz && \
    # Create function-only scripts
    mkdir -p /tools && \
    echo '#!/bin/bash\necho "cache"' > /tools/cache && \
    echo '#!/bin/bash\necho "artifact"' > /tools/artifact && \
    echo '#!/bin/bash\n"$@"' > /tools/retry && \
    chmod +x /tools/*

# Final ultra-minimal stage
FROM semaphoreci/agent:v2.3.0
USER root
ENV USER=semaphore

# Remove everything non-essential from base image
RUN apt-get update && \
    # Remove unnecessary packages that might be in base
    apt-get remove -y --purge \
        vim* nano* emacs* \
        man-db manpages* \
        info install-info \
        doc-base \
        apt-utils \
        2>/dev/null || true && \
    # Install only absolute essentials
    apt-get install -y --no-install-recommends libssl1.1 libncurses5 zlib1g && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/lib/dpkg/info/*

# Copy minimal Erlang (just the beam VM and core libs)
COPY --from=erlang-builder /minimal/* /usr/local/bin/
ENV ERL_LIBS=/usr/local/lib

# Copy minimal tools
COPY --from=tools /sem /usr/local/bin/sem
COPY --from=tools /tools/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Ultra-minimal setup
RUN mkdir -p /opt/semaphore && chown ${USER}:${USER} /opt/semaphore

# Copy your scripts
COPY shutdown.sh /opt/semaphore/shutdown
COPY entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/* && chown ${USER}:${USER} /opt/semaphore/*

# Nuclear cleanup - remove everything possible
RUN rm -rf /tmp/* /var/tmp/* /var/log/* /var/cache/* /var/backups/* && \
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    rm -rf /usr/share/locale/* /usr/share/terminfo/* /usr/share/zoneinfo/* && \
    rm -rf /usr/share/vim /usr/share/nano /usr/share/emacs* 2>/dev/null || true && \
    find /usr -name "*.h" -delete 2>/dev/null || true && \
    find /usr -name "*.a" -delete 2>/dev/null || true && \
    find /usr -name "*.la" -delete 2>/dev/null || true && \
    find /usr -name "*.pc" -delete 2>/dev/null || true && \
    # Remove more from semaphoreci base if possible
    rm -rf /root/.cache /root/.local 2>/dev/null || true

USER ${USER}
WORKDIR /home/${USER}
ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
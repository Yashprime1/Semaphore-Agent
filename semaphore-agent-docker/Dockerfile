FROM semaphoreci/agent:v2.3.0

USER root

# Set timezone non-interactively
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    build-essential 

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws/

# Install Semaphore CLI tools
RUN echo "Installing Semaphore CLI..." && \
    curl -L https://github.com/semaphoreci/cli/releases/download/v0.32.0/sem_Linux_x86_64.tar.gz | tar -xz && \
    mv sem /usr/local/bin/ && \
    chmod +x /usr/local/bin/sem 

RUN curl -L https://github.com/semaphoreci/toolbox/releases/download/v1.28.0/self-hosted-linux.tar | tar -xz && \
    mv spc /usr/local/bin/ && \
    chmod +x /usr/local/bin/spc 
RUN echo "Installing SPC (Semaphore Pipeline Compiler)..." && \
    curl -L https://github.com/semaphoreci/spc/releases/download/v1.12.1/spc_Linux_x86_64.tar.gz | tar -xz && \
    mv spc /usr/local/bin/ && \
    chmod +x /usr/local/bin/spc && \
RUN echo "Installing erlang..." && \
    curl -L https://github.com/erlang/otp/releases/download/OTP-28.0.1/otp_src_28.0.1.tar.gz | tar -xz && \
    apt install -y build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils openjdk-11-jdk libssl-dev && \
    cd otp_src_28.0.1/ && \
    ./configure && \
    make && \
    make install 
RUN echo "Installing When..." && \
    curl -L https://github.com/renderedtext/when/releases/download/v1.2.1/when_otp_26 -o when_otp_26 && \
    mv when_otp_26 /usr/local/bin/when && \
    chmod +x /usr/local/bin/when 

COPY shutdown.sh /opt/semaphore/shutdown
RUN chmod +x /opt/semaphore/shutdown

COPY entrypoint.sh /opt/semaphore/entrypoint.sh
RUN chmod +x /opt/semaphore/entrypoint.sh


ENTRYPOINT ["/opt/semaphore/entrypoint.sh"]
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    vim \
    nano \
    sudo \
    # Python and pip
    python3 \
    python3-pip \
    python3-venv \
    # Ansible dependencies
    sshpass \
    openssh-client \
    # Network tools
    dnsutils \
    iputils-ping \
    net-tools \
    netcat \
    # Image processing for QR codes
    qrencode \
    libqrencode-dev \
    imagemagick \
    # JSON/YAML processing
    jq \
    yq \
    # Build tools
    build-essential \
    # WireGuard tools
    wireguard-tools \
    # Additional utilities
    zip \
    unzip \
    tar \
    gzip \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --no-cache-dir \
    ansible \
    ansible-lint \
    jinja2 \
    pyyaml \
    requests \
    qrcode[pil] \
    cryptography

# Install latest yq (YAML processor)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# Create workspace directory
WORKDIR /workspace

# Copy post-create script
COPY post-create.sh /tmp/post-create.sh
RUN chmod +x /tmp/post-create.sh

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Configure bash prompt
RUN echo 'export PS1="\[\e[32m\][\[\e[m\]\[\e[33m\]\u\[\e[m\]\[\e[32m\]@\[\e[m\]\[\e[36m\]questvpn\[\e[m\]\[\e[32m\]]\[\e[m\] \[\e[34m\]\w\[\e[m\] \[\e[32m\]\\$\[\e[m\] "' >> /home/vscode/.bashrc

# Add helpful aliases
RUN echo 'alias ll="ls -lah"' >> /home/vscode/.bashrc && \
    echo 'alias k="kubectl"' >> /home/vscode/.bashrc && \
    echo 'alias d="docker"' >> /home/vscode/.bashrc && \
    echo 'alias dc="docker-compose"' >> /home/vscode/.bashrc && \
    echo 'alias ap="ansible-playbook"' >> /home/vscode/.bashrc

# Set correct ownership
RUN chown -R vscode:vscode /home/vscode

USER vscode

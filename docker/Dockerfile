# TF2 MGE Server Docker Image
FROM ubuntu:22.04

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
        lib32gcc-s1 \
        lib32stdc++6 \
        lib32z1 \
        libcurl4-gnutls-dev:i386 \
        libncurses5:i386 \
        libtinfo5:i386 \
        libsdl2-2.0-0:i386 \
        curl \
        wget \
        ca-certificates \
        iproute2 \
        net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create container user
RUN useradd -m -d /home/container -s /bin/bash container

# Set up working directory
WORKDIR /home/container

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to container user
USER container
ENV USER=container HOME=/home/container

# Expose game ports
EXPOSE 27015/tcp 27015/udp 27020/udp 27005/udp

ENTRYPOINT ["/entrypoint.sh"]
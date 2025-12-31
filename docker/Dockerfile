# ===========================================
# TF2 MGE Server - Custom Build
# ===========================================

# Stage 1: Download SourceMod and MetaMod
FROM ubuntu:22.04 AS sourcemod-metamod
WORKDIR /download
ARG INSTALL_DIR=/server/tf
RUN mkdir -p "${INSTALL_DIR}"

ARG METAMOD_VERSION=1.12.0-git1219
ARG METAMOD_FILE_NAME=mmsource-${METAMOD_VERSION}-linux.tar.gz
ARG METAMOD_URL=https://mms.alliedmods.net/mmsdrop/1.12/${METAMOD_FILE_NAME}
ARG METAMOD_CHECKSUM=f16e67d8de30a46edb2aee8909a885f9f025993284596bb0cfc83b5b32eae05f
ADD --checksum=sha256:${METAMOD_CHECKSUM} ${METAMOD_URL} .
RUN tar xf "${METAMOD_FILE_NAME}" -C "${INSTALL_DIR}/"

ARG SOURCEMOD_VERSION=1.12.0-git7210
ARG SOURCEMOD_FILE_NAME=sourcemod-${SOURCEMOD_VERSION}-linux.tar.gz
ARG SOURCEMOD_URL=https://sm.alliedmods.net/smdrop/1.12/${SOURCEMOD_FILE_NAME}
ARG SOURCEMOD_CHECKSUM=86caf2da0b1e9503c01296b175ace4662106880b57123abf88961feeb2fa9278
ADD --checksum=sha256:${SOURCEMOD_CHECKSUM} ${SOURCEMOD_URL} .
RUN tar xf "${SOURCEMOD_FILE_NAME}" -C "${INSTALL_DIR}/"

# Stage 2: Download Plugins
FROM ubuntu:22.04 AS plugins
SHELL ["/bin/bash", "-c"]

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  ca-certificates curl unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /download
ARG PLUGIN_INSTALL_DIR=/server/tf
RUN mkdir -p "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/"

# MGEMod - customize version as needed
ARG MGEMOD_VERSION=v3.1.0-beta9
ARG MGEMOD_URL=https://github.com/maxijabase/MGEMod/releases/download/${MGEMOD_VERSION}/mge.zip
RUN curl -L "${MGEMOD_URL}" -o mge.zip \
  && unzip -q -n mge.zip -d "${PLUGIN_INSTALL_DIR}/"

# Stage 3: Final image
FROM steamcmd/steamcmd:ubuntu-22

RUN export DEBIAN_FRONTEND=noninteractive \
  && dpkg --add-architecture i386 \
  && apt-get -y update \
  && apt-get install -y software-properties-common \
  && add-apt-repository multiverse \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  lib32gcc-s1 lib32z1 libncurses5:i386 libbz2-1.0:i386 \
  lib32stdc++6 libtinfo5:i386 libcurl3-gnutls:i386 \
  wget unzip gettext-base libbsd0 netcat-openbsd \
  && rm -rf /var/lib/apt/lists/*

ARG USER=tf2
ARG HOME=/home/$USER
ARG SERVER_DIR=$HOME/server
ARG APP_ID=232250

ENV USER=$USER \
    HOME=$HOME \
    SERVER_DIR=$SERVER_DIR \
    APP_ID=$APP_ID

RUN useradd --home-dir $HOME --create-home --shell /bin/bash $USER
USER $USER
WORKDIR $HOME

# Install TF2 Dedicated Server (with retries for flaky steamcmd)
RUN steamcmd +quit || true \
  && for i in 1 2 3 4 5; do \
       steamcmd +force_install_dir $SERVER_DIR \
         +login anonymous \
         +app_update $APP_ID validate \
         +quit \
       && break || echo "Attempt $i failed, retrying..." && sleep 5; \
     done \
  && mkdir -p $HOME/.steam \
  && ln -s $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32

WORKDIR $SERVER_DIR

# Copy SourceMod and MetaMod from build stage
COPY --from=sourcemod-metamod --chown=tf2 /server/tf/ "${SERVER_DIR}/tf/"

# Copy plugins from build stage
COPY --from=plugins --chown=tf2 /server/tf/ "${SERVER_DIR}/tf/"

# Disable problematic default plugins
RUN mkdir -p "${SERVER_DIR}/tf/addons/sourcemod/plugins/disabled" \
  && mv "${SERVER_DIR}/tf/addons/sourcemod/plugins/"{nextmap,funcommands,funvotes}.smx \
     "${SERVER_DIR}/tf/addons/sourcemod/plugins/disabled/" 2>/dev/null || true

# Copy custom configs (your MGE settings)
COPY --chown=tf2 tf/ "${SERVER_DIR}/tf/"

# Environment variables
ENV IP=0.0.0.0 \
    PORT=27015 \
    CLIENT_PORT=27016 \
    STEAM_PORT=27018 \
    STV_PORT=27020 \
    SERVER_TOKEN="" \
    RCON_PASSWORD="changeme" \
    SERVER_HOSTNAME="MGE Server" \
    SERVER_PASSWORD="" \
    STV_NAME="Source TV" \
    STV_PASSWORD=""

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Generate server.cfg from environment\n\
cat > "${SERVER_DIR}/tf/cfg/server.cfg" <<EOF\n\
hostname "${SERVER_HOSTNAME}"\n\
rcon_password "${RCON_PASSWORD}"\n\
sv_password "${SERVER_PASSWORD}"\n\
tv_name "${STV_NAME}"\n\
tv_password "${STV_PASSWORD}"\n\
EOF\n\
\n\
# Start the server\n\
exec "${SERVER_DIR}/srcds_run" \\\n\
  -game tf \\\n\
  -ip "${IP}" \\\n\
  -port "${PORT}" \\\n\
  +clientport "${CLIENT_PORT}" \\\n\
  +tv_port "${STV_PORT}" \\\n\
  ${SERVER_TOKEN:++sv_setsteamaccount "${SERVER_TOKEN}"} \\\n\
  "$@"\n\
' > entrypoint.sh && chmod +x entrypoint.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD nc -z -u localhost ${PORT} || exit 1

EXPOSE ${PORT}/tcp ${PORT}/udp ${STV_PORT}/udp

ENTRYPOINT ["./entrypoint.sh"]
CMD ["+sv_pure", "1", "+map", "mge_training_v8_beta4b", "+maxplayers", "24"]

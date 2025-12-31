# ===========================================
# TF2 MGE Server - Custom MGEMod Build
# ===========================================
# Extends tf2-base (has TF2 + SourceMod pre-installed)
# Adds YOUR custom MGEMod version

FROM ghcr.io/melkortf/tf2-base:latest

USER root
RUN apt-get update && apt-get install -y --no-install-recommends unzip \
  && rm -rf /var/lib/apt/lists/*

# Remove any existing MGE plugin if present
RUN rm -f "${SERVER_DIR}/tf/addons/sourcemod/plugins/mge"*.smx 2>/dev/null || true

# Download YOUR custom MGEMod version
ARG MGEMOD_VERSION=v3.1.0-beta9
ARG MGEMOD_URL=https://github.com/maxijabase/MGEMod/releases/download/${MGEMOD_VERSION}/mge.zip
ADD --chown=tf2:tf2 ${MGEMOD_URL} /tmp/mge.zip
RUN unzip -q -o /tmp/mge.zip -d "${SERVER_DIR}/tf/" \
  && chown -R tf2:tf2 "${SERVER_DIR}/tf/" \
  && rm /tmp/mge.zip

USER tf2

# Copy your custom configs (overrides base image defaults)
COPY --chown=tf2 tf/ "${SERVER_DIR}/tf/"

# Default MGE server settings
ENV SERVER_HOSTNAME="MGE Server"

CMD ["+sv_pure", "1", "+map", "mge_training_v8_beta4b", "+maxplayers", "24"]

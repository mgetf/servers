# ===========================================
# TF2 MGE Server - Custom MGEMod Build
# ===========================================
# Extends tf2-base (has TF2 + SourceMod pre-installed)
# Adds YOUR custom MGEMod version

FROM ghcr.io/melkortf/tf2-base:latest

# Remove any existing MGE plugin if present
RUN rm -f "${SERVER_DIR}/tf/addons/sourcemod/plugins/mge"*.smx 2>/dev/null || true

# Download YOUR custom MGEMod version
ARG MGEMOD_VERSION=v3.1.0-beta9
ARG MGEMOD_URL=https://github.com/maxijabase/MGEMod/releases/download/${MGEMOD_VERSION}/mge.zip
RUN curl -L "${MGEMOD_URL}" -o /tmp/mge.zip \
  && unzip -q -o /tmp/mge.zip -d "${SERVER_DIR}/tf/" \
  && rm /tmp/mge.zip

# Copy your custom configs (overrides base image defaults)
COPY --chown=tf2 tf/ "${SERVER_DIR}/tf/"

# Default MGE server settings
ENV SERVER_HOSTNAME="MGE Server" \
    RCON_PASSWORD="changeme"

CMD ["+sv_pure", "1", "+map", "mge_training_v8_beta4b", "+maxplayers", "24"]

#!/bin/bash
set -euo pipefail

# Wings installation for Pterodactyl
# Requires: PANEL_URL, PANEL_TOKEN, NODE_NAME env vars

echo "Installing Docker..."
curl -fsSL https://get.docker.com | bash
systemctl enable --now docker

echo "Configuring system..."
# Enable swap accounting
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1 /' /etc/default/grub
update-grub

# Create wings directory
mkdir -p /etc/pterodactyl
cd /etc/pterodactyl

echo "Installing Wings..."
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod +x /usr/local/bin/wings

# Create systemd service
cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Generate Wings configuration via Panel API
echo "Fetching Wings configuration from Panel..."
curl -X POST "${PANEL_URL}/api/application/nodes/${NODE_NAME}/configuration" \
     -H "Authorization: Bearer ${PANEL_TOKEN}" \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -o /etc/pterodactyl/config.yml

# Start Wings
systemctl daemon-reload
systemctl enable --now wings

echo "Wings installation complete"
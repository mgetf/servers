#!/bin/bash
# TF2 MGE Server Installation Script for Pterodactyl Egg

cd /mnt/server

# Install SteamCMD and TF2
echo "Installing SteamCMD..."
mkdir -p /mnt/server/steamcmd
cd /mnt/server/steamcmd
curl -sSL -o steamcmd_linux.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd_linux.tar.gz
cd /mnt/server

# Install TF2
echo "Installing TF2 Dedicated Server..."
./steamcmd/steamcmd.sh +force_install_dir /mnt/server +login anonymous +app_update 232250 validate +quit

# Install Metamod:Source
echo "Installing Metamod:Source..."
MM_VERSION=$(curl -s https://mms.alliedmods.net/mmsdrop/1.12/mmsource-latest-linux)
curl -sSL "https://mms.alliedmods.net/mmsdrop/1.12/${MM_VERSION}" -o metamod.tar.gz
tar -xzf metamod.tar.gz -C /mnt/server/tf

# Install SourceMod
echo "Installing SourceMod..."
SM_VERSION=$(curl -s https://sm.alliedmods.net/smdrop/1.12/sourcemod-latest-linux)
curl -sSL "https://sm.alliedmods.net/smdrop/1.12/${SM_VERSION}" -o sourcemod.tar.gz
tar -xzf sourcemod.tar.gz -C /mnt/server/tf

# Install MGEMod
echo "Installing MGEMod..."
cd /mnt/server/tf/addons/sourcemod/plugins
curl -sSL "https://github.com/maxijabase/MGEMod/releases/latest/download/mgemod.smx" -o mgemod.smx

# Create required directories
mkdir -p /mnt/server/tf/cfg
mkdir -p /mnt/server/tf/maps
mkdir -p /mnt/server/tf/addons/sourcemod/configs

# Download MGE maps
echo "Downloading MGE maps..."
cd /mnt/server/tf/maps
for map in mge_training_v8_beta4b mge_chillypunch_final4_fix2 mge_oihguv_sucks_a12 endif_b4; do
    echo "Downloading ${map}..."
    curl -sSL "https://fastdl.mge.tf/maps/${map}.bsp" -o "${map}.bsp" || echo "Failed to download ${map}"
done

# Create server.cfg
cat > /mnt/server/tf/cfg/server.cfg <<'EOF'
hostname "{{SERVER_NAME}}"
rcon_password "{{RCON_PASSWORD}}"
sv_password "{{SERVER_PASSWORD}}"
sv_contact "admin@mge.tf"
sv_region 255
sv_lan 0

// Performance settings
fps_max 0
sv_maxrate 0
sv_minrate 100000
sv_maxcmdrate 66
sv_mincmdrate 66
sv_maxupdaterate 66
sv_minupdaterate 66

// MGE specific
mp_tournament 1
mp_tournament_restart
sv_alltalk 1
mp_forcecamera 0
sv_allow_votes 0
mp_timelimit 0
mp_winlimit 0

// SourceTV
tv_enable 0

// Logging
log on
sv_logbans 1
sv_logecho 1
sv_logfile 1
sv_log_onefile 0

// Execute MGE config
exec mgemod
EOF

# Create databases.cfg for SourceMod
cat > /mnt/server/tf/addons/sourcemod/configs/databases.cfg <<'EOF'
"Databases"
{
    "default"
    {
        "driver"    "sqlite"
        "database"  "sourcemod-local"
    }
    
    "mgemod"
    {
        "driver"    "sqlite"
        "database"  "mgemod"
    }
}
EOF

echo "Installation complete!"
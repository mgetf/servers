#!/bin/bash

log_info "Installing lib32gcc-s1"
sudo apt-get install lib32gcc-s1

log_info "Creating Steam directory"
mkdir -p ~/Steam
pushd ~/Steam

log_info "Downloading SteamCMD"
if [ ! -f "steamcmd.sh" ]; then
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
else 
    log_info "SteamCMD already exists"
fi

log_info "Running SteamCMD"
mkdir -p /opt/tf2-server/server
./steamcmd.sh +login anonymous +force_install_dir /opt/tf2-server/server +app_update 232250 +quit

popd  # Return to the original directory
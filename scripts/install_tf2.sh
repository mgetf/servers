#!/bin/bash

log_info "Installing lib32gcc-s1"
sudo apt-get install lib32gcc-s1

log_info "Creating Steam directory"
mkdir ~/Steam && pushd ~/Steam

log_info "Downloading SteamCMD"
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

log_info "Running SteamCMD"
./steamcmd.sh +login anonymous +force_install_dir /opt/tf2-server/server +app_update 232250 +quit

popd  # Return to the original directory
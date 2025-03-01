#!/bin/bash

log_info "Installing lib32gcc-s1"
sudo apt-get install lib32gcc-s1

sudo dpkg --add-architecture i386
sudo apt update

sudo apt-get install libstdc++6:i386
sudo apt-get install libncurses6:i386 libtinfo6:i386 libcurl4-gnutls-dev:i386

log_info "Creating Steam directory"
mkdir -p ~/Steam
pushd ~/Steam

log_info "Downloading SteamCMD"
if [ ! -f "steamcmd.sh" ]; then
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -
else 
    log_info "SteamCMD already exists"
fi

log_info "symlinking cause steam is dumb"

mkdir -p ~/.steam/sdk32
mkdir -p ~/.steam/sdk64

ln -s ~/Steam/linux32/steamclient.so ~/.steam/sdk32/steamclient.so
ln -s ~/Steam/linux64/steamclient.so ~/.steam/sdk64/steamclient.so


log_info "Running SteamCMD"

mkdir -p /opt/tf2-server/server
./steamcmd.sh +login anonymous +force_install_dir /opt/tf2-server/server +app_update 232250 +quit

popd  # Return to the original directory
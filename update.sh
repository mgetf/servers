#!/bin/bash
pushd ~/Steam
./steamcmd.sh +login anonymous +force_install_dir /opt/tf2-server/server +app_update 232250 +quit
popd
# {{ run tf2, isntall mm/sm, then mge plugin, test it. }}
#!/bin/bash
set -e

cd $HOME/hlserver/tf2/tf

mm_url=$(wget -q -O - "https://www.metamodsource.net/downloads.php?branch=stable" | grep -oP -m1 "https://[a-z.]+/mmsdrop/[0-9.]+/mmsource-(.*)-linux.tar.gz")
sm_url=$(wget -q -O - "http://www.sourcemod.net/downloads.php?branch=stable" | grep -oP -m1 "https://[a-z.]+/smdrop/[0-9.]+/sourcemod-(.*)-linux.tar.gz")

wget -nv $mm_url
wget -nv $sm_url

tar -xvzf mmsource-*-linux.tar.gz
tar -xvzf sourcemod-*-linux.tar.gz

rm *.tar.gz

# prevent automatic map switch
rm addons/sourcemod/plugins/{nextmap.smx,funcommands.smx,funvotes.smx}
pushd /opt/tf2-server/server/tf/addons
cd $SERVER/tf2/tf/addons

wget -nv https://github.com/dalegaard/srctvplus/releases/download/v3.0/srctvplus.vdf
wget -nv https://github.com/dalegaard/srctvplus/releases/download/v3.0/srctvplus.so

cd $SERVER/tf2/tf/addons/sourcemod/plugins

## SetTeam
wget -nv https://github.com/spiretf/setteam/raw/master/plugin/setteam.smx

cd $SERVER/tf2/tf

# SM-RipExt-Websocket
wget -nv "https://github.com/eldoradoel/sm-ripext-websocket/releases/download/2.4.0/sm-ripext--ubuntu-20.04.zip" -O "ripext.zip"
unzip -o ripext.zip
rm ripext.zip

wget -nv "https://github.com/mgetf/mgeme_sm/archive/master.zip"
unzip -o master.zip
rm mgeme_sm-master/README.md
rm mgeme_sm-master/LICENSE
cp mgeme_sm-master/* . -r
rm master.zip

cd $SERVER/tf2/tf/addons/sourcemod/plugins
chmod 0664 *.smx
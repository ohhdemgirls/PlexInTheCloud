#!/bin/bash
source vars

# Install NZBget
## Download and decompress nzbget
wget rarlab.com/rar/unrarsrc-5.2.7.tar.gz
tar -xvf unrarsrc-5.2.7.tar.gz

## Compile and Install
cd unrar
make -j2 -f makefile
install -v -m755 unrar /usr/bin

## Cleanup
cd ..
rm -R unrar
rm unrarsrc-5.2.7.tar.gz
NZBGETLATEST=$(wget http://nzbget.net/download/ -O - | grep run | awk -F "[\"]" '{print $4}' | head -n1)
wget $NZBGETLATEST -O nzbget-latest-bin-linux.run
sh nzbget-latest-bin-linux.run --destdir /opt/nzbget
rm nzbget-latest-bin-linux.run
chown -R $username:$username /opt/nzbget

## Create directory structure
mkdir -p /home/$username/nzbget
mkdir -p /home/$username/nzbget/completed
mkdir -p /home/$username/nzbget/intermediate
mkdir -p /home/$username/nzbget/nzb 
mkdir -p /home/$username/nzbget/queue
mkdir -p /home/$username/nzbget/tmp
mkdir -p /home/$username/nzbget/scripts

# Install nzbToMedia Post-Processing Scripts
## Install dependencies
apt-get install -y unrar unzip tar p7zip ffmpeg

## Install nzbToMedia.py
git clone https://github.com/clinton-hall/nzbToMedia.git /home/$username/nzbget/scripts

## Copy default scripts to new location
cp /opt/nzbget/scripts/* /home/$username/nzbget/scripts/

## Add our upload script that uploads contents to Amazon Cloud Drive
tee "/home/$username/nzbget/scripts/uploadTV.sh" > /dev/null <<EOF
#!/bin/bash

#######################################
### NZBGET POST-PROCESSING SCRIPT   ###

# Rclone upload to Amazon Cloud Drive

# Wait for NZBget/Sickrage to finish moving files
sleep 10s

# Upload
rclone move -c /home/$username/$local/tv $encrypted:tv

# Tell Plex to update the Library
#wget http://localhost:32400/library/sections/2/refresh?X-Plex-Token=kp9dTjwxqD8zQyznSBRb

# Send PP Success code
exit 93
EOF

chmod +x /home/$username/nzbget/scripts/uploadTV.sh

## Create symlink that the scripts look for when running Python
ln -sf /usr/bin/python2.7 /usr/bin/python2

## Copy default config file
cp /home/$username/nzbget/scripts/autoProcessMedia.cfg.spec /home/$username/nzbget/scripts/autoProcessMedia.cfg

## Ensure permissions
systemctl stop rcloneMount.service
chown -R $username:$username /home/$username
systemctl start rcloneMount.service

## Tell nzbget to start as the default user
sed -i "/DaemonUsername=/c\DaemonUsername=$username" /opt/nzbget/nzbget.conf

## Modify config file
# PATHS
sed -i "s/^MainDir=.*/MainDir=/home/$username/nzbget/g" /opt/nzbget/nzbget.conf
sed -i 's|^DestDir=.*|DestDir=${MainDir}/completed|g' /opt/nzbget/nzbget.conf
sed -i 's|^InterDir=.*|InterDir=${MainDir}/intermediate|g' /opt/nzbget/nzbget.conf

# NEWS-SERVERS
sed -i "s/^Server1.Active=.*/Server1.Active=yes/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Name=.*/Server1.Name=$newsServer/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Host=.*/Server1.Host=$nsHostname/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Port=.*/Server1.Port=$nsPort/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Username=.*/Server1.Username=$nsUsername/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Password=.*/Server1.Password=$nsPassword/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Encryption=.*/Server1.Encryption=$nsEncryption/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Connections=.*/Server1.Connections=$nsConnections/g" /opt/nzbget/nzbget.conf
sed -i "s/^Server1.Retention=.*/Server1.Retention=$nsRetention/g" /opt/nzbget/nzbget.conf

# SECURITy
sed -i "s/^ControlUsername=.*/ControlUsername=$username/g" /opt/nzbget/nzbget.conf
sed -i "s/^ControlPassword=.*/ControlPassword=$passwd/g" /opt/nzbget/nzbget.conf
sed -i "s/^DaemonUsername=.*/DaemonUsername=$username/g" /opt/nzbget/nzbget.conf

# CATEGORIES
## Movies
sed -i "s/^Category1.Name=.*/Category1.Name=movies/g" /opt/nzbget/nzbget.conf
sed -i "s|^Category1.DestDir=.*|Category1.DestDir=/home/$username/nzbget/completed/movies|g" /opt/nzbget/nzbget.conf
sed -i "s/^Category1.PostScript=.*/Category1.PostScript=nzbToCouchPotato.py, Logger.py, uploadMovies.sh/g" /opt/nzbget/nzbget.conf

## TV
sed -i "s/^Category2.Name=.*/Category2.Name=tv/g" /opt/nzbget/nzbget.conf
sed -i "s|^Category2.DestDir=.*|Category2.DestDir=/home/$username/nzbget/completed/tv|g" /opt/nzbget/nzbget.conf
sed -i "s/^Category2.PostScript=.*/Category2.PostScript=nzbToSickBeard.py, Logger.py, uploadTV.sh/g" /opt/nzbget/nzbget.conf

## Music
sed -i "s/^Category3.Name=.*/Category3.Name=music/g" /opt/nzbget/nzbget.conf
sed -i "s|^Category3.DestDir=.*|Category3.DestDir=/home/$username/nzbget/completed/music|g" /opt/nzbget/nzbget.conf
sed -i "s/^Category3.PostScript=.*/Category3.PostScript=nzbToHeadPhones.py, Logger.py, uploadMusic.sh/g" /opt/nzbget/nzbget.conf

## Comics
sed -i "s/^Category4.Name=.*/Category4.Name=comics/g" /opt/nzbget/nzbget.conf
sed -i "s|^Category4.DestDir=.*|Category4.DestDir=/home/$username/nzbget/completed/comics|g" /opt/nzbget/nzbget.conf
sed -i "s/^Category4.PostScript=.*/Category4.PostScript=nzbToMylar.py, Logger.py, uploadComics.sh/g" /opt/nzbget/nzbget.conf

# DOWNLOAD QUEUE
sed -i "s/^ArticleCache=.*/ArticleCache=1900/g" /opt/nzbget/nzbget.conf
sed -i "s/^WriteBuffer=.*/WriteBuffer=1024/g" /opt/nzbget/nzbget.conf

# LOGGING
sed -i "s/^WriteLog=.*/WriteLog=rotate/g" /opt/nzbget/nzbget.conf

# UNPACK
sed -i 's|^UnrarCmd=.*|UnrarCmd=${AppDir}/unrar|g' /opt/nzbget/nzbget.conf
sed -i 's|^SevenZipCmd=.*|SevenZipCmd=${AppDir}/7za|g' /opt/nzbget/nzbget.conf

# EXTENSTION SCRIPTS
sed -i 's/^ScriptOrder=.*/ScriptOrder=nzbToMedia*.py, Email.py, Logger.py, upload*.sh/g' /opt/nzbget/nzbget.conf

## nzbToMedia - Post Processing Scripts
# nzbToCouchPotato
sed -i 's/^nzbToCouchPotato.py:auto_update=.*/nzbToCouchPotato.py:auto_update=1/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToCouchPotato.py:cpsCategory=.*/nzbToCouchPotato.py:cpsCategory=movies/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToCouchPotato.py:cpsdelete_failed=.*/nzbToCouchPotato.py:cpsdelete_failed=1/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToCouchPotato.py:getSubs=.*/nzbToCouchPotato.py:getSubs=1/g' /opt/nzbget/nzbget.conf
sed -i "s/^nzbToCouchPotato.py:subLanguages=.*/nzbToCouchPotato.py:subLanguages=$openSubtitlesLang/g" /opt/nzbget/nzbget.conf
sed -i "s|^nzbToCouchPotato.py:cpswatch_dir=.*|nzbToCouchPotato.py:cpswatch_dir=/home/$username/nzbget/completed/movies|g" /opt/nzbget/nzbget.conf

# nzbToSickBeard
sed -i 's/^nzbToSickBeard.py:auto_update=.*/nzbToSickBeard.py:auto_update=1/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToSickBeard.py:sbCategory=.*/nzbToSickBeard.py:sbCategory=tv/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToSickBeard.py:sbdelete_failed=.*/nzbToSickBeard.py:sbdelete_failed=1/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToSickBeard.py:getSubs=.*/nzbToSickBeard.py:getSubs=1/g' /opt/nzbget/nzbget.conf
sed -i "s/^nzbToSickBeard.py:subLanguages=.*/nzbToSickBeard.py:subLanguages=$openSubtitlesLang/g" /opt/nzbget/nzbget.conf
sed -i "s/^nzbToSickBeard.py:sbusername=.*/nzbToSickBeard.py:sbusername=$username/g" /opt/nzbget/nzbget.conf
sed -i "s/^nzbToSickBeard.py:sbpassword=.*/nzbToSickBeard.py:sbpassword=$passwd/g" /opt/nzbget/nzbget.conf
sed -i "s|^nzbToSickBeard.py:sbwatch_dir=.*|nzbToSickBeard.py:sbwatch_dir=/home/$username/nzbget/completed/tv|g" /opt/nzbget/nzbget.conf

# nzbToMylar
sed -i 's/^nzbToMylar.py:auto_update=.*/nzbToMylar.py:auto_update=1/g' /opt/nzbget/nzbget.conf
sed -i 's/^nzbToMylar.py:myCategory=.*/nzbToMylar.py:myCategory=comics/g' /opt/nzbget/nzbget.conf
sed -i "s/^nzbToMylar.py:myusername=.*/nzbToMylar.py:myusername=$username/g" /opt/nzbget/nzbget.conf
sed -i "s/^nzbToMylar.py:mypassword=.*/nzbToMylar.py:mypassword=$passwd/g" /opt/nzbget/nzbget.conf
sed -i "s|^nzbToMylar.py:mywatch_dir=.*|nzbToMylar.py:mywatch_dir=/home/$username/nzbget/completed/comics|g" /opt/nzbget/nzbget.conf

## Start nzbget at boot
tee "/etc/systemd/system/nzbget.service" > /dev/null <<EOF
[Unit]
Description=NZBGet Daemon
Documentation=http://nzbget.net/Documentation
After=rcloneMount.service
RequiresMountsFor=/mnt/usbstorage

[Service]
User=$username
Group=$username
Type=forking
ExecStart=/opt/nzbget/nzbget -c /opt/nzbget/nzbget.conf -D
ExecStop=/opt/nzbget/nzbget -Q
ExecReload=/opt/nzbget/nzbget -O
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl start nzbget
systemctl enable nzbget

echo ''
echo "Do you want to allow remote access to NZBget?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 6789; echo ''; echo "Port 6789 open, NZBget is now available over the internet."; echo ''; break;;
        No ) echo "Port 6789 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 6789:localhost:6789"; echo "and then open localhost:6789 on your browser."; exit;;
    esac
done

cat << EOF
## Now run 04-sickrage.sh to set up Sickrage.
EOF

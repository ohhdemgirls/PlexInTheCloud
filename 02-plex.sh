#!/bin/bash

source vars

# Download and Install Plex
wget https://downloads.plex.tv/plex-media-server/1.3.3.3148-b38628e/plexmediaserver_1.3.3.3148-b38628e_amd64.deb
dpkg -i plex*.deb
rm plex*.deb

mkdir -p /etc/systemd/system/plexmediaserver.service.d
tee "/etc/systemd/system/plexmediaserver.service.d/local.conf" > /dev/null <<EOF
[Unit]
Description= Start Plexmediaserver as our user, and don't do it until our mount script has finished.
After=rcloneMount.service

[Service]
User=$username
Group=$username
EOF

chown -R $username:$username /var/lib/plexmediaserver

# Start Plex and enable on boot
systemctl daemon-reload
systemctl start plexmediaserver
systemctl enable plexmediaserver 

# Open port
ufw allow 32400

cat << EOF
## ON LOCAL MACHINE - incognito works best for some reason
## otherwise Plex may tell you that it "can't save the settings"
## When you try to login via port forwarding.
# ssh $username@$ipaddr -L 8888:localhost:32400
#    open `localhost:8888/web` in a browser
#    login with your previously created Plex account.
#    if you don't have one, create one now.
#    Now enable remote access:
#        Remote Access-->Enable
#    Open IPADDRESS:32400/web
EOF

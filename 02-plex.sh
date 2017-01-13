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

echo ''
echo "You need to manually enable remote management for Plex."
echo "Issue the following command on your LOCAL machine:"
echo "ssh $username@$ipaddr -L 8888:localhost:32400"
echo "open `localhost:8888/web` in a browser"
echo "Either login or create a new Plex account."
echo "Now enable remote access: Remote Access ->> Enable"
echo ''
echo "You should now be able to access plex at: $ipaddr:32400/web"
echo "Have you enabled remote access?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 8181; echo ''; echo "Cool, moving along."; echo ''; break;;
        No ) echo "You should really do that before continuing."; exit;;
    esac
done

# Install PlexPy
git clone https://github.com/JonnyWong16/plexpy.git /opt/plexpy/
chown -R $username:$username /opt/plexpy

# Add Systemd Service File
tee "/etc/systemd/system/plexpy.service" > /dev/null <<EOF
[Unit]
Description=PlexPy - Stats for Plex Media Server usage
After=plexmediaserver.service

[Service]
ExecStart=/opt/plexpy/PlexPy.py --quiet --daemon --nolaunch --config /opt/plexpy/config.ini --datadir /opt/plexpy
GuessMainPID=no
Type=forking
User=$username
Group=$username

[Install]
WantedBy=multi-user.target
EOF

# Start Plexpy and enable on boot
systemctl daemon-reload
systemctl start plexpy
systemctl enable plexpy

echo ''
echo "Do you want to allow remote access to PlexPy?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 8181; echo ''; echo "Port 8181 open, PlexPy is now available over the internet."; echo ''; break;;
        No ) echo "Port 8181 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 8181:localhost:8181"; echo "and then open localhost:8181 on your browser."; exit;;
    esac
done

# Install Plex Requests
exec sudo -i -u $username /bin/bash - << eof
curl "https://install.meteor.com/?release=1.2.1" | sh
git clone https://github.com/lokenx/plexrequests-meteor.git /opt/plexrequests/
cd /opt/plexrequests
meteor &
PID=$!
sleep 10m
kill $PID
eof

# Add Systemd Service File
tee "/etc/systemd/system/plexrequest.service" > /dev/null <<EOF
[Unit]
Description=PlexRequest
After=plexmediaserver.service

[Service]
User=$username
Type=simple
WorkingDirectory=/opt/plexrequests
ExecStart=/usr/local/bin/meteor
KillMode=process
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start PlexRequests and enable on boot
systemctl daemon-reload
systemctl start plexrequest
systemctl enable plexrequest

echo ''
echo "Do you want to allow remote access to PlexRequests?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 3000; echo ''; echo "Port 3000 open, PlexRequests is now available over the internet."; echo ''; break;;
        No ) echo "Port 3000 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 3000:localhost:3000"; echo "and then open localhost:3000 on your browser."; exit;;
    esac
done

#!/bin/bash
source vars

# Install CouchPotato
## Install dependencies
apt-get install -y git-core libffi-dev libssl-dev zlib1g-dev libxslt1-dev libxml2-dev python python-pip python-dev build-essential

pip install lxml cryptography pyopenssl

## Install Couchpotato
mkdir /opt/couchpotato
sudo -u $username git https://github.com/CouchPotato/CouchPotatoServer.git /opt/couchpotato
chown -R $username:$username /opt/couchpotato

## Systemd Service file
cp -v /opt/couchpotato/init/couchpotato.service /etc/systemd/system/couchpotato.service
chown root:root /etc/systemd/system/couchpotato.service
chmod 644 /etc/systemd/system/couchpotato.service

## Start couchpotato at boot
tee "/etc/systemd/system/couchpotato.service" > /dev/null <<EOF
[Unit]
Description=CouchPotato application instance
After=rcloneMount.service

[Service]
ExecStart=/opt/couchpotato/CouchPotato.py
Type=simple
User=$username
Group$username

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start couchpotato
systemctl enable couchpotato

echo ''
echo "Do you want to allow remote access to CouchPotato?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 8080; echo ''; echo "Port 8080 open, CouchPotato is now available over the internet."; echo ''; break;;
        No ) echo "Port 8080 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 8080:localhost:8080"; echo "and then open localhost:8080 on your browser."; exit;;
    esac
done

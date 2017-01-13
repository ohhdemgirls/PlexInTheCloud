#!/bin/bash
source vars

# Install CouchPotato
## Install dependencies
apt-get install -y git-core libffi-dev libssl-dev zlib1g-dev libxslt1-dev libxml2-dev python python-pip python-dev build-essential

pip install lxml cryptography pyopenssl

## Install Couchpotato
mkdir /opt/couchpotato
git clone https://github.com/CouchPotato/CouchPotatoServer.git /opt/couchpotato/
chown -R $username:$username /opt/couchpotato

## Write CouchPotato API to nzbget.conf so it can send post-processing requests
### Copy the api key from the CP config file
cpAPI=$(cat /home/$username/.couchpotato/settings.conf | grep "api_key = ................................" | cut -d= -f 2)

### Cut the single blank space that always gets added to the front of $cpAPI
cpAPInew="$(sed -e 's/[[:space:]]*$//' <<<${cpAPI})"

### Write the API key to nzbget.conf
sed -i "s/^nzbToCouchPotato.py:cpsapikey=.*/nzbToCouchPotato.py:cpsapikey=$cpAPInew/g" /opt/nzbget/nzbget.conf

## Configure CouchPotato
### CouchPotato stores our passwords as md5sum hashes...heh heh heh
cppassword=$(echo -n $passwd | md5sum | cut -d ' ' -f 1)
sed -i "s/^username =.*/username = $username/g" /home/$username/.couchpotato/settings.conf
sed -i "s/^password =.*/password = $cppassword/g" /home/$username/.couchpotato/settings.conf

### nzbget
sed -i "s/^username = nzbget/username = $username/g" /home/$username/.couchpotato/settings.conf
sed -i "s/^category = Movies/category = movies/g" /home/$username/.couchpotato/settings.conf

perl -i -0pe "s/username = nzbget\ncategory = Movies\ndelete_failed = True\nmanual = 0\nenabled = 0\npriority = 0\nssl = 0/username = $username\ncategory = movies\ndelete_failed = True\nmanual = 0\nenabled = 1\npriority = 0\n ssl = 0/" /home/$username/.couchpotato/settings.conf
perl -i -0pe "s/6789\npassword =/6789\npassword = $passwd\n/" /home/$username/.couchpotato/settings.conf

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
Group=$username

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start couchpotato
systemctl enable couchpotato
systemctl restart couchpotato

echo ''
echo "Do you want to allow remote access to CouchPotato?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 5050; echo ''; echo "Port 5050 open, CouchPotato is now available over the internet."; echo ''; break;;
        No ) echo "Port 5050 left closed. You can still access it from your local machine by issuing the following command: ssh $username@$ipaddr -L 5050:localhost:5050"; echo "and then open localhost:5050 on your browser."; exit;;
    esac
done


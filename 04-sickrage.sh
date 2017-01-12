#!/bin/bash
source vars

# Install Sickrage
## Install dependencies
apt-get install -y unrar-free git-core openssl libssl-dev python2.7

## Install Sickrage
mkdir /opt/sickrage
git clone https://github.com/SickRage/SickRage.git /opt/sickrage/
chown -R $username:$username /opt/sickrage

## Modify config file
sed -i "s/^tv_download_dir =.*/tv_download_dir = \/home\/$username\/nzbget\/completed\/tv/g" /opt/sickrage/config.ini
sed -i "s/^root_dirs =.*/root_dirs = 0|\/home\/$username\/$overlayfuse\/tv/g" /opt/sickrage/config.ini
sed -i "s|naming_pattern =.*|naming_pattern = Season %0S\\\%S_N-S%0SE%0E-%E_N-%Q_N|g" /opt/sickrage/config.ini

sed -i "s/^web_username =.*/web_username = $username/g" /opt/sickrage/config.ini
sed -i "s/^web_password =.*/web_password = $passwd/g" /opt/sickrage/config.ini

sed -i "s/^nzbget_username =.*/nzbget_username = $username/g" /opt/sickrage/config.ini
sed -i "s/^nzbget_password =.*/nzbget_password = $passwd/g" /opt/sickrage/config.ini

sed -i "s/^opensubtitles_password =.*/opensubtitles_password = $openSubtitlesPassword/g" /opt/sickrage/config.ini
sed -i "s/^opensubtitles_username =.*/opensubtitles_username = $openSubtitlesUsername/g" /opt/sickrage/config.ini
sed -i "s/^subtitles_languages =.*/subtitles_languages = $openSubtitlesLang/g" /opt/sickrage/config.ini

sed -i 's/^SUBTITLES_SERVICES_LIST =.*/SUBTITLES_SERVICES_LIST = "opensubtitles,addic7ed,legendastv,shooter,subscenter,thesubdb,tvsubtitles"/g' /opt/sickrage/config.ini
sed -i "s/^use_subtitles =.*/use_subtitles = 1/g" /opt/sickrage/config.ini
sed -i 's/^SUBTITLES_SERVICES_ENABLED =.*/SUBTITLES_SERVICES_ENABLED = 1|0|0|0|0|0|0|0|0/g' /opt/sickrage/config.ini

sed -i "s/^use_failed_downloads =.*/use_failed_downloads = 1/g" /opt/sickrage/config.ini
sed -i "s/^delete_failed =.*/delete_failed = 1/g" /opt/sickrage/config.ini

## Systemd Service file
cp -v /opt/sickrage/runscripts/init.systemd /etc/systemd/system/sickrage.service
chown root:root /etc/systemd/system/sickrage.service
chmod 644 /etc/systemd/system/sickrage.service

## Start sickrage at boot
tee "/etc/systemd/system/sickrage.service" > /dev/null <<EOF
[Unit]
Description=SickRage Daemon
After=rcloneMount.service

[Service]
User=$username
Group=$username

Type=forking
GuessMainPID=no
ExecStart=/usr/bin/python2.7 /opt/sickrage/SickBeard.py -q --daemon --nolaunch --datadir=/opt/sickrage

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start sickrage
systemctl enable sickrage

echo ''
echo "Do you want to allow remote access to Sickrage?"
echo "If so, you need to tell UFW to open the port."
echo "Otherwise, you can use SSH port forwarding."
echo ''
echo "Would you like us to open the port in UFW?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) ufw allow 8081; echo ''; echo "Port 8081 open, Sickrage is now available over the internet."; echo ''; break;;
        No ) echo "Port 8081 left closed. You can still access it on your local machine by issuing the following command: ssh $username@$ipaddr -L 8081:localhost:8081"; echo "and then open localhost:8081 on your browser."; exit;;
    esac
done


cat << EOF
## Now run 05-couchpotato.sh to set up CouchPotato.
EOF

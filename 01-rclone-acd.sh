#!/bin/bash

source vars

# Install dependencies
apt-get install -y git unionfs-fuse unzip

# Install rclone
curl -O http://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip rclone-current-linux-amd64.zip
cd rclone-*-linux-amd64
cp rclone /usr/sbin/
chown root:root /usr/sbin/rclone
chmod 755 /usr/sbin/rclone

# Configure rclone
cat << EOF
rclone config

    n       # New remote
    AMZ     # name
    1       # Choose "Amazon Drive"
            # press enter, leave blank for Client Id
            # press enter, leave blank for Client Secret
    n       # press n for headless setup
            # On your personal computer with rclone installed, type: rclone authorize "amazon cloud drive" (at a terminal prompt, quotes included in the command)
            # Login to Amazon using the browser that rclone opened on your personal computer.
            # Get the code from your Terminal window on your personal computer and copy-paste it to your remote server.
    y       # to accept everything, "Yes this is OK"
    q       # Quit
EOF

echo ''
echo "Did you add your rclone AMZ mount in previous step?"
echo ''
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) echo 'You need to do that before we can move on, exiting.'; exit;;
    esac
done

cat << EOF
# RCLONE ENCRYPT
rclone config

    n               # New remote
    $encrypted      # name
    5               # Choose "crypt"
    AMZ             # remote name you set up previously + folder
    2               # Choose "Encrypt the filenames"
    g               # Choose "Generate random password"
    128             # Strength of password
    y               # Accept password (and write it down for backup!!!!)
    g               # Choose "Generate random password" for salt
    128             # Strength of salt
    y               # Accept salt (and write it down for backup!!!!)
    y               # Accept everything "Yes this is OK"
    q               # Quit
EOF

echo ''
echo "Did you add your rclone crypt mount in previous step?"
echo ''
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) echo 'You need to do that before we can move on, exiting.'; exit;;
    esac
done

echo ''
echo "Did you back up/write down your password and salt?"
echo ''
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) echo "It's your choice, but losing those means you'll be unable to recover any of your encrypted files."; break;;
    esac
done

# Create your base directories
mkdir -p /home/$username/$encrypted
mkdir -p /home/$username/$local
mkdir -p /home/$username/$overlayfuse

# Create your mount script
mkdir -p /home/$username/scripts
tee "/home/$username/scripts/rcloneMount.sh" > /dev/null <<EOF
#!/bin/bash
rclone mount \
    --read-only \
    --allow-non-empty \
    --dir-cache-time 1m \
    --max-read-ahead 2G \
    --acd-templink-threshold 0\
    --bwlimit 0 \
    --checkers 32 \
    --contimeout 15s \
    --low-level-retries 1 \
    --no-check-certificate \
    --quiet \
    --retries 3 \
    --stats 0 \
    --timeout 30s \
    $encrypted: /home/$username/$encrypted/ & 

sleep 3s
unionfs-fuse -o cow,max_readahead=2000000000 /home/$username/$local=RW:/home/$username/$encrypted=RO /home/$username/$overlayfuse 
EOF

chmod +x /home/$username/scripts/rcloneMount.sh
chown -R $username:$username /home/$username

# Tell Systemd to mount at boot
## Create the service file
tee "/etc/systemd/system/rcloneMount.service" > /dev/null <<EOF
[Unit]
Description=Mount Amazon Cloud Drive
Documentation=https://acd-cli.readthedocs.org/en/latest/
After=network-online.target

[Service]
Type=forking
User=$username
ExecStart=/bin/bash /home/$username/scripts/rcloneMount.sh
ExecStop=/bin/umount /home/$username/$encrypted 
ExecStop=/bin/umount /home/$username/$overlayfuse
Restart=on-abort

[Install]
WantedBy=default.target
EOF

## Start the service & enable it at boot
systemctl daemon-reload
systemctl start rcloneMount.service
systemctl enable rcloneMount.service

cat << EOF
## Now run 02-plex.sh to set up Plex.
EOF

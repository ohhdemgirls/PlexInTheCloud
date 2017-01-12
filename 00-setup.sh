#!/bin/bash

source vars

# Stop apt-get from hanging on security updates
echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf

# Update and Upgrade
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Set hostname
hostnamectl set-hostname $hostname

# Set Timezone
timedatectl set-timezone $timezone

# Update hosts file
echo "127.0.0.1  $hostname" >> /etc/hosts
echo "127.0.0.1  localhost.localdomain   localhost" >> /etc/hosts

# Set up automatic security updates
apt install unattended-upgrades

echo -e "APT::Periodic::Update-Package-Lists \"1\";\n\
APT::Periodic::Download-Upgradeable-Packages \"1\";\n\
APT::Periodic::AutocleanInterval \"7\";\n\
APT::Periodic::Unattended-Upgrade \"1\";\n"\
> /etc/apt/apt.conf.d/10periodic

# Create user
useradd -m -s /bin/bash $username

# Create Password
echo $username:$passwd | chpasswd

# Add user to Sudoers
adduser $username sudo
sed --in-place 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers

# Install & Configure SSH
sed -z 's/PermitRootLogin yes\|$/PermitRootLogin no/' /etc/ssh/sshd_config
sed -z 's/PasswordAuthentication yes\|$/PasswordAuthentication no/' /etc/ssh/sshd_config
echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config
systemctl restart sshd

# Install & Configure Fail2Ban
apt-get -y install fail2ban

sed 's/\(^[[:alpha:]]\)/# \1/' /etc/fail2ban/fail2ban.conf | sudo tee /etc/fail2ban/fail2ban.local &> /dev/null
sed 's/\(^[a-z tab]\)/# \1/' /etc/fail2ban/jail.conf | sudo tee /etc/fail2ban/jail.local &> /dev/null

# Allow SSH
ufw allow ssh
ufw default allow outgoing
ufw default deny incoming

# Enable Firewall
ufw --force enable

echo ''
echo "Now you'll need to push your local SSH keys to this remote server so that you can reboot and login as that user."
echo "Logging in as root won't work once you reboot."
echo "So, from your local machine run:"
echo "ssh-copy-id $username@$ipaddr"
echo "Now you should be able to log in as your user."
echo "ssh $username@$ipaddr"
echo ''
echo "Have you pushed your key?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "Ok, rebooting now."; echo ''; reboot -h now; break;;
        No ) echo "Ok, you can still SSH in as root until we reboot."; exit;;
    esac
done

#!/bin/bash

sudo apt install -y bind9 bind9utils bind9-doc knot-dnsutils firewalld lftp libldap-common apparmor-utils

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 dns2.vagrant-dummy-ops.lab dns2/' -i /etc/hosts
echo '192.168.1.202 vsftp.vagrant-dummy-ops.lab' | sudo tee -a /etc/hosts

# Set the dns resolver
echo 'nameserver 192.168.1.200' | sudo tee /etc/resolv.conf
echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf
echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf

# Copy dns2 configuration templates
echo "Copying dns2 configuration files..."
sudo cp /vagrant_templates/named.conf.local /etc/bind/named.conf.local
sudo cp /vagrant_templates/vagrant_vsftp.crt /usr/local/share/ca-certificates/vagrant_vsftp.crt
sudo update-ca-certificates
# We set the 'rw' perms on /etc/bind (that's why we use a copied apparmor file)
# Remember that apparmor enforced files and processes can be seen using: sudo aa-status
sudo cp /vagrant_templates/usr.sbin.named /etc/apparmor.d/usr.sbin.named
# We reload the conf to take effect
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.named

# Set TSIG
cd /etc/bind/
# Download the tsig.key file from the ftp server
sudo lftp -u $DNS_MANAGER_USER_NAME,$DNS_MANAGER_USER_PASSWORD -e "set ftp:ssl-allow yes; set ssl:verify-certificate yes; get /data/dns_manager/tsig.key -o tsig.key; exit" ftp://vsftp.vagrant-dummy-ops.lab
echo 'include "/etc/bind/tsig.key";' | sudo tee -a '/etc/bind/named.conf'

# Set DNSSEC
sudo mkdir /etc/bind/keys
cd /etc/bind/keys
# Fetch the public keys from the ftp host
sudo lftp -u $DNS_MANAGER_USER_NAME,$DNS_MANAGER_USER_PASSWORD -e "set ftp:ssl-allow yes; set ssl:verify-certificate yes; mget /data/dns_manager/*.key; exit" ftp://vsftp.vagrant-dummy-ops.lab
sudo rm -f /etc/bind/keys/tsig.key

# Notice setgid bit is set on /etc/bind (owner|group: root|bind)
sudo chown -R bind:bind /etc/bind

# Set hostname
sudo hostnamectl set-hostname dns2

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# Update firewall rules
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload

sudo systemctl restart bind9

# umount vagrant sync folder
sudo umount /vagrant

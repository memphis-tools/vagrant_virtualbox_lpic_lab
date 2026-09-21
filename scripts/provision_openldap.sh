#!/bin/bash

sudo apt-get -y install firewalld

sudo firewall-cmd --add-service=ldaps --permanent
sudo firewall-cmd --reload

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed -i '/127.0.0.1/s/$/ openldap/' /etc/hosts
sudo sed '/^127.0.0.1/s//127.0.0.1 openldap.vagrant-dummy-ops.lab openldap/' -i /etc/hosts
echo '192.168.1.211 openldap.vagrant-dummy-ops.lab' | sudo tee -a /etc/hosts

sudo mkdir /mnt/kerberos_keytabs
sudo mkdir /etc/ssl/localcerts/
sudo cp /vagrant_templates/vagrant_openldap.crt /etc/ssl/localcerts/vagrant_openldap.crt
sudo cp /vagrant_templates/vagrant_openldap.key /etc/ssl/localcerts/vagrant_openldap.key

# Create client user
sudo groupadd $NAS_KDC_GROUP_NAME -g 2502
sudo useradd $NAS_KDC_USER_NAME -u 1202 -g $NAS_KDC_GROUP_NAME -s /sbin/nologin

sudo chown -R $NAS_KDC_USER_NAME:$NAS_KDC_GROUP_NAME /mnt/kerberos_keytabs

# Set hostname
sudo hostnamectl set-hostname openldap

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

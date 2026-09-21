#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install firewalld openvpn easy-rsa openresolv libldap-common

# Copy certificate and key pair files
sudo mkdir -p /etc/ssl/localcerts
# sudo cp /vagrant_templates/vagrant_openvpn.crt /etc/ssl/localcerts/vagrant_openvpn.crt
# sudo cp /vagrant_templates/vagrant_openvpn.key /etc/ssl/localcerts/vagrant_openvpn.key
# sudo cp /vagrant_templates/vagrant_openvpn.crt /usr/local/share/ca-certificates/vagrant_openvpn.crt
# sudo update-ca-certificates
# Copy the pre-generated diffie-hellman
sudo cp /vagrant_templates/dh2048.pem /etc/openvpn/server/dh2048.pem

# We got 2 interfaces for all virtual machines
# eth0 is for example at 10.0.2.0/24, it resolves the virtualbox for DNS 10.0.2.3 : publiv
# eth1 is "private", and is at 192.168.1.0/24
sudo firewall-cmd --add-service=openvpn --permanent
sudo firewall-cmd --zone=trusted --add-interface=eth1 --permanent
sudo firewall-cmd --zone=public --add-interface=eth0 --permanent
sudo firewall-cmd --zone=public --add-forward --permanent
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 openvpn.vagrant-dummy-ops.lab openvpn/' -i /etc/hosts

# Set hostname
sudo hostnamectl set-hostname openvpn

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

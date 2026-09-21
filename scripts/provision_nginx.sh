#!/bin/bash

sudo apt-get -y install firewalld nginx libldap-common

# Copy nginx certificate and key pair files
sudo mkdir -p /etc/ssl/localcerts
sudo cp /vagrant_templates/vagrant_nginx.crt /etc/ssl/localcerts/vagrant_nginx.crt
sudo cp /vagrant_templates/vagrant_nginx.key /etc/ssl/localcerts/vagrant_nginx.key

sudo update-ca-certificates

sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload


# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 nginx.vagrant-dummy-ops.lab nginx/' -i /etc/hosts

# Set hostname
sudo hostnamectl set-hostname nginx

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

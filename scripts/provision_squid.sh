#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install firewalld python3-firewall libldap-common ldap-utils

# Copy certificate and key pair files
sudo mkdir -p /etc/squid/ssl_cert/
sudo cp /vagrant_templates/vagrant_squid.crt /etc/squid/ssl_cert/vagrant_squid.crt
sudo cp /vagrant_templates/vagrant_squid.key /etc/squid/ssl_cert/vagrant_squid.key
sudo cp /vagrant_templates/vagrant_squid_mitm_ca.crt /etc/squid/ssl_cert/vagrant_squid_mitm_ca.crt
sudo cp /vagrant_templates/vagrant_squid_mitm_ca.key /etc/squid/ssl_cert/vagrant_squid_mitm_ca.key
sudo cp /vagrant_templates/squid.dhparam.pem /etc/squid/squid.dhparam.pem
sudo chmod 0600 /etc/squid/ssl_cert/vagrant_squid.key
sudo chmod 0600 /etc/squid/ssl_cert/vagrant_squid_mitm_ca.key
sudo chown -R proxy: /etc/squid/

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed -i '/127.0.0.1/s/$/ squid/' /etc/hosts
echo '192.168.1.210 squid.vagrant-dummy-ops.lab' | sudo tee -a /etc/hosts

# Set hostname
sudo hostnamectl set-hostname squid

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

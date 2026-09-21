#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install nfs-common krb5-user libldap-common

# Copy nginx certificate and key pair files
sudo mkdir -p /etc/ssl/localcerts
sudo cp /vagrant_templates/vagrant_bastion.crt /etc/ssl/localcerts/vagrant_bastion.crt
sudo cp /vagrant_templates/vagrant_bastion.key /etc/ssl/localcerts/vagrant_bastion.key
sudo chmod 0600 /etc/ssl/localcerts/vagrant_bastion.key

sudo umount /vagrant

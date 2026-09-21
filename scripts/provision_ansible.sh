#!/bin/bash

sudo apt-get -y install ansible sshpass libldap-common

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 ansible.vagrant-dummy-ops.lab ansible/' -i /etc/hosts

# Set hostname
sudo hostnamectl set-hostname ansible

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

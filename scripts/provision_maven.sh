#!/bin/bash

sudo apt-get -y install maven

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed -i '/127.0.0.1/s/$/ maven/' /etc/hosts

# Set hostname
sudo hostnamectl set-hostname maven

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

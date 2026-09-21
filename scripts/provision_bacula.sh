#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install firewalld nfs-common krb5-user libldap-common bacula bacula-director bacula-sd bacula-console

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 bacula.vagrant-dummy-ops.lab bacula/' -i /etc/hosts

# 9103 is the StorageDaemon (9101 for director, and 9102 for FileDaemon/client)
sudo firewall-cmd --add-port=9103/tcp --permanent
sudo firewall-cmd --reload

# POSTGRESQL setup
sudo runuser -u postgres -- psql -c 'DROP DATABASE bacula;'
sudo rm -f /etc/bacula/common_default_passwords
# nb: change directory error seems harmless
sudo -u postgres db_name=vagrant_bacula /usr/share/bacula-director/create_postgresql_database
sudo -u postgres db_name=vagrant_bacula /usr/share/bacula-director/make_postgresql_tables
sudo -u postgres db_name=vagrant_bacula db_user=baculo /usr/share/bacula-director/grant_postgresql_privileges
sudo runuser -u postgres -- psql -c "ALTER ROLE baculo WITH PASSWORD '@pplepie94';"

# copy configuration files
sudo cp /vagrant_templates/bacula-dir.conf /etc/bacula/bacula-dir.conf
sudo mkdir -p /opt/bacula/backups
sudo chown -R bacula: /opt/bacula/
sudo cp /vagrant_templates/bacula-sd.conf /etc/bacula/bacula-sd.conf
sudo cp /vagrant_templates/bconsole.conf /etc/bacula/bconsole.conf

# Set hostname
sudo hostnamectl set-hostname bacula

# Set timezone
sudo timedatectl set-timezone Europe/Paris

sudo umount /vagrant

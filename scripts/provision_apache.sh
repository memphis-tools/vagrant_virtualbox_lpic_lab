#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install xfsprogs parted autofs openssl nfs-common firewalld krb5-user apparmor-utils apache2 php-fpm apache2-utils curl libsasl2-modules libldap-common

# Update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 apache.vagrant-dummy-ops.lab apache/' -i /etc/hosts
echo '192.168.1.212 apache.vagrant-dummy-ops.lab apache.vagrant' | sudo tee -a /etc/hosts

# Format the /dev/sdb disk (attached from virtualbox)
sudo parted -s /dev/sdb mklabel msdos mkpart primary xfs 1Mib 100%
sudo mkfs.xfs /dev/sdb1
sudo xfs_admin -L APACHE_LOGS /dev/sdb1
sudo chown www-data:www-data /var/log/apache2/
sudo chmod 0750 /var/log/apache2/
sudo mount -t xfs -L APACHE_LOGS /var/log/apache2
sudo touch /var/log/apache2/access.log
sudo touch /var/log/apache2/error.log
sudo touch /var/log/apache2/other_vhosts_access.log

# Create client user
sudo groupadd $NAS_APACHE_GROUP_NAME -g 2500
sudo useradd $NAS_APACHE_USER_NAME -u 1200 -g $NAS_APACHE_GROUP_NAME -s /sbin/nologin

# Setup autofs
echo '/- /etc/auto.apache' | sudo tee /etc/auto.master
echo '/var/www/html/ -fstype=nfs4,rw,defaults,nosuid,nodev nas.vagrant-dummy-ops.lab:/mnt/apache' | sudo tee /etc/auto.apache
sudo systemctl restart autofs

# Copy certificate and key pair files
sudo mkdir -p /etc/ssl/localcerts
sudo cp /vagrant_templates/vagrant_apache.crt /etc/ssl/localcerts/vagrant_apache.crt
sudo cp /vagrant_templates/vagrant_apache.key /etc/ssl/localcerts/vagrant_apache.key
sudo cp /vagrant_templates/vagrant_apache.crt /usr/local/share/ca-certificates/vagrant_apache.crt
sudo update-ca-certificates

# Setup apache webpage access
sudo htpasswd -cb /etc/apache2/.htpasswd admin $APACHE_PASSWORD_ACCESS
sudo chmod 0600 /etc/apache2/.htpasswd
sudo chown -R www-data: /etc/apache2/.htpasswd

# Setup apache logrotate
sudo cp /vagrant_templates/logrotate /etc/logrotate.d/apache2
sudo systemctl restart logrotate.service

# Setup the global ServerName directive
echo 'ServerName apache.vagrant-dummy-ops.lab' | sudo tee -a '/etc/apache2/apache2.conf'

# Setup the virtualhost
sudo cp /vagrant_templates/dummy-apache.conf /etc/apache2/sites-available/dummy-apache.conf

# Setup apache
sudo a2enmod ssl proxy_fcgi setenvif
sudo a2dissite 000-default.conf
sudo a2ensite dummy-apache.conf
sudo rm /etc/apache2/sites-available/000-default.conf
sudo rm /etc/apache2/sites-available/default-ssl.conf

# Setup firewall
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload

sudo systemctl restart apache2

# Send a dummy test message
curl -X POST -u "admin:$APACHE_PASSWORD_ACCESS" https://apache.vagrant-dummy-ops.lab/index.php -d 'nom=somebody' -d 'mail=root@dovecot.vagrant-dummy-ops.lab' -d'message=test' -H "Content-Type: application/x-www-form-urlencoded"

# Set hostname
sudo hostnamectl set-hostname apache

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

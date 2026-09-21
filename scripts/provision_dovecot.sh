#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postfix firewalld dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-sieve  mailutils mutt python3-passlib libldap-common

# Copy dovecot configuration templates
echo "Copying dns1 configuration files..."
sudo unlink /etc/dovecot/private/dovecot.key
sudo unlink /etc/dovecot/private/dovecot.pem
sudo cp /vagrant_templates/dovecot.conf /etc/dovecot/dovecot.conf
sudo cp /vagrant_templates/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
sudo cp /vagrant_templates/10-mail.conf /etc/dovecot/conf.d/10-mail.conf
sudo cp /vagrant_templates/10-master.conf /etc/dovecot/conf.d/10-master.conf
sudo cp /vagrant_templates/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf
sudo cp /vagrant_templates/15-lda.conf /etc/dovecot/conf.d/15-lda.conf
sudo cp /vagrant_templates/20-lmtp.conf /etc/dovecot/conf.d/20-lmtp.conf
sudo cp /vagrant_templates/90-sieve.conf /etc/dovecot/conf.d/90-sieve.conf
sudo cp /vagrant_templates/auth-system.conf.ext /etc/dovecot/conf.d/auth-system.conf.ext
sudo cp /vagrant_templates/vagrant_dovecot.crt /etc/dovecot/private/dovecot.pem
sudo cp /vagrant_templates/vagrant_dovecot.key /etc/dovecot/private/dovecot.key

# Setup the mail box and sieve filters
sudo cp -r /vagrant_templates/Maildir /etc/skel/
sudo cp -r /vagrant_templates/sieve /etc/skel/
# Remind we set the symlink according to: /etc/dovecot/conf.d/90-sieve.conf
# sieve = file:~/sieve;active=~/.dovecot.sieve
sudo ln -s /etc/skel/sieve/filters.sieve /etc/skel/.dovecot.filter

# Setup sieve_before filter
sudo mkdir -p /etc/dovecot/sieve.d/
sudo cp /vagrant_templates/global-before.sieve /etc/dovecot/sieve.d/global-before.sieve


sudo useradd --system --no-create-home --home-dir / --shell /usr/sbin/nologin vmail
sudo mkdir -p /var/mail/vhosts
sudo chown vmail:vmail /var/mail/vhosts
sudo chmod 750 /var/mail/vhosts

# Setup firewall
sudo firewall-cmd --add-service=smtp --permanent
sudo firewall-cmd --add-service=smtps --permanent
sudo firewall-cmd --add-service=pop3s --permanent
sudo firewall-cmd --add-service=imaps --permanent
sudo firewall-cmd --reload

# Set perms and restart dovecot
sudo chown -R dovecot: /etc/dovecot/
sudo systemctl restart dovecot

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 dovecot.vagrant-dummy-ops.lab dovecot/' -i /etc/hosts

# Optionally update timezone
sudo timedatectl set-timezone 'Europe/Paris'

# Set hostname
sudo hostnamectl set-hostname dovecot

# umount vagrant sync folder
sudo umount /vagrant

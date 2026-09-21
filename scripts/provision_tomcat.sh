#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install firewalld default-jre nfs-common curl

VAGRANT_TOMCAT_KEYSTORE_PASSWORD=$VAGRANT_TOMCAT_KEYSTORE_PASSWORD
TOMCAT_DIR="/opt/tomcat"
TOMCAT_CONF_DIR="$TOMCAT_DIR/conf"

# Find latest version
BASE_URL="https://dlcdn.apache.org/tomcat/tomcat-11"
VERSION=$(curl -fsSL "$BASE_URL/" \
  | grep -oE 'v11\.[0-9]+\.[0-9]+/' \
  | sed 's|/||' \
  | sort -V \
  | tail -1)

echo "Latest Tomcat version: $VERSION"
TOMCAT_VERSION="${VERSION#v}"
TOMCAT_URL="$BASE_URL/$VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"

# Install and Deploy Tomcat
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

echo "Downloading: $TOMCAT_URL"
cd /opt
wget "$TOMCAT_URL"
tar -xzf apache-tomcat-$TOMCAT_VERSION.tar.gz
rm apache-tomcat-$TOMCAT_VERSION.tar.gz
mv /opt/apache-tomcat-$TOMCAT_VERSION $TOMCAT_DIR
chown -R tomcat: $TOMCAT_DIR
ln -s /opt/tomcat/bin/startup.sh /usr/local/bin/start_tomcat
ln -s /opt/tomcat/bin/shutdown.sh /usr/local/bin/stop_tomcat

# Copy Tomcat configuration templates and files
echo "Copying Tomcat configuration files..."
sudo cp /vagrant_templates/server.xml $TOMCAT_CONF_DIR/
sudo cp /vagrant_templates/tomcat-users.xml $TOMCAT_CONF_DIR/
sudo cp /vagrant_templates/vagrant_tomcat.p12 $TOMCAT_CONF_DIR/
sudo cp /vagrant_templates/vagrant_tomcat_fullchain.pem /usr/local/share/ca-certificates/vagrant_tomcat_fullchain.crt
sudo cp /vagrant_templates/context.xml $TOMCAT_DIR/webapps/manager/META-INF/context.xml
sudo cp /vagrant_templates/context.xml $TOMCAT_DIR/webapps/host-manager/META-INF/context.xml

sudo mkdir /etc/ssl/localcerts/
sudo cp /vagrant_templates/vagrant_tomcat.crt /etc/ssl/localcerts/vagrant_tomcat.crt
sudo cp /vagrant_templates/vagrant_tomcat.key /etc/ssl/localcerts/vagrant_tomcat.key
echo "$VAGRANT_TOMCAT_KEYSTORE_PASSWORD" | sudo tee $TOMCAT_CONF_DIR/keystore-pass.properties > /dev/null
sudo chmod 0600 $TOMCAT_CONF_DIR/keystore-pass.properties

sudo groupadd $DEVOPS_GROUP_NAME -g 2500
sudo useradd a1b2 -g $DEVOPS_GROUP_NAME -m -d /appli/a1b2 -s /bin/bash
sudo cp /etc/skel/.bash* /etc/skel/.profile /appli/a1b2
sudo chown -R a1b2: /appli/a1b2
sudo chmod 0700 /appli/a1b2

sudo useradd b2c3 -g $DEVOPS_GROUP_NAME -m -d /appli/b2c3 -s /bin/bash
sudo cp /etc/skel/.bash* /etc/skel/.profile /appli/b2c3
sudo chown -R b2c3: /appli/b2c3
sudo chmod 0700 /appli/b2c3

sudo chown -R tomcat: $TOMCAT_DIR/

# Update sudoers rule
echo '%app_devops ALL=(ALL) NOPASSWD: \' | sudo tee /etc/sudoers.d/app_devops
echo '  /usr/sbin/showmount -e nas' | sudo tee -a /etc/sudoers.d/app_devops

# Copy systemd service file
echo "Installing tomcat.service systemd unit..."
sudo cp /vagrant_templates/tomcat.service /etc/systemd/system/tomcat.service

# Reload systemd daemon and enable Tomcat
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 tomcat.vagrant-dummy-ops.lab tomcat/' -i /etc/hosts

# Set hostname
sudo hostnamectl set-hostname tomcat

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# Setup firewall
sudo firewall-cmd --add-port=8005/tcp --permanent
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload

# Mount the nfs4 volume from nas host (Ne peut pas fonctionner avant les jobs ansible)
sudo mount -t nfs4 127.0.0.1:/mnt /mnt -o rw,nosuid,nodev

# umount vagrant sync folder
sudo umount /vagrant

# curl --user tomcat:tomcat "https://localhost:8443/manager/text/stop?path=/app1"
# curl --user tomcat:tomcat "https://localhost:8443/manager/text/start?path=/app1"

#!/bin/bash

sudo apt-get -y install firewalld libldap-common ifenslave

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 kdc.vagrant-dummy-ops.lab kdc/' -i /etc/hosts

sudo firewall-cmd --add-service=kerberos --permanent
sudo firewall-cmd --reload

sudo mkdir /mnt/kerberos_keytabs
sudo mkdir /etc/ssl/localcerts/
sudo cp /vagrant_templates/vagrant_kdc.crt /etc/ssl/localcerts/vagrant_kdc.crt
sudo cp /vagrant_templates/vagrant_kdc.key /etc/ssl/localcerts/vagrant_kdc.key

# Create client user
sudo groupadd $NAS_KDC_GROUP_NAME -g 2502
sudo useradd $NAS_KDC_USER_NAME -u 1202 -g $NAS_KDC_GROUP_NAME -s /sbin/nologin

sudo chown -R $NAS_KDC_USER_NAME:$NAS_KDC_GROUP_NAME /mnt/kerberos_keytabs

# Remind that package ifenslave has been installed (see Vagrantfile)
sudo tee -a /etc/modules <<EOF
bonding
EOF

sudo tee /etc/network/interfaces >/dev/null <<EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet manual

auto eth2
iface eth2 inet manual

auto bond0
iface bond0 inet static
    address 192.168.1.207
    netmask 255.255.255.0
    bond-mode active-backup
    bond-slaves eth1 eth2
    bond-primary eth1
    bond-miimon 100
    bond-downdelay 200
    bond-updelay 200
    bond-fail-over-mac 1
EOF

sudo ip link set eth1 down
sudo ip link set eth2 down
sudo systemctl restart networking
sudo ip link set bond0 up

# remind 'EOF' (not EOF) to disable variable expansion
sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null <<'EOF'
Acquire::http::Proxy="http://$SQUID_USERNAME:$SQUID_PASSWORD@squid.vagrant-dummy-ops.lab:3128";
Acquire::https::Proxy="http://$SQUID_USERNAME:$SQUID_PASSWORD@squid.vagrant-dummy-ops.lab:3128";
EOF

# Set hostname
sudo hostnamectl set-hostname kdc

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

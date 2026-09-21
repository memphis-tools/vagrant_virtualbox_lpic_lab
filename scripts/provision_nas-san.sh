#!/bin/bash

sudo apt-get -y install xfsprogs parted lvm2 nfs-kernel-server nfs-common stunnel4 firewalld libldap-common targetcli-fb

# Set the pvs/vgs/lvs and format
sudo pvcreate /dev/sdb --force
sudo vgcreate vg_nas /dev/sdb
sudo lvcreate vg_nas -n lv_apache -L 200m
sudo lvcreate vg_nas -n lv_tomcat -L 400m
sudo lvcreate vg_nas -n lv_kerberos -L 100m

sudo mkfs.ext4 /dev/mapper/vg_nas-lv_apache
sudo mkfs.ext4 /dev/mapper/vg_nas-lv_tomcat
sudo mkfs.ext4 /dev/mapper/vg_nas-lv_kerberos
sudo mkdir /mnt/apache /mnt/tomcat /mnt/kerberos
sudo mount -t ext4 -o rw,defaults,nosuid,nodev,noexec /dev/mapper/vg_nas-lv_apache /mnt/apache
sudo mount -t ext4 -o rw,defaults,nosuid,nodev,noexec /dev/mapper/vg_nas-lv_tomcat /mnt/tomcat
sudo mount -t ext4 -o rw,defaults,nosuid,nodev,noexec /dev/mapper/vg_nas-lv_kerberos /mnt/kerberos
sudo chmod 0755 /mnt/apache /mnt/tomcat /mnt/kerberos

# Copy files to be shared
sudo cp -r /vagrant_templates/apache/* /mnt/apache/
sudo cp -r /vagrant_templates/tomcat/* /mnt/tomcat/

# Create client users
sudo groupadd $NAS_APACHE_GROUP_NAME -g 2500
sudo useradd $NAS_APACHE_USER_NAME -u 1200 -g $NAS_APACHE_GROUP_NAME -s /sbin/nologin

sudo groupadd $NAS_TOMCAT_GROUP_NAME -g 2501
sudo useradd $NAS_TOMCAT_USER_NAME -u 1201 -g $NAS_TOMCAT_GROUP_NAME -s /sbin/nologin

sudo groupadd $NAS_KDC_GROUP_NAME -g 2502
sudo useradd $NAS_KDC_USER_NAME -u 1202 -g $NAS_KDC_GROUP_NAME -s /sbin/nologin

# Set perms on shared resources
sudo chown -R $NAS_APACHE_USER_NAME:$NAS_APACHE_GROUP_NAME /mnt/apache/
sudo chown -R $NAS_TOMCAT_USER_NAME:$NAS_TOMCAT_GROUP_NAME /mnt/tomcat/
sudo chown -R $NAS_KDC_USER_NAME:$NAS_KDC_GROUP_NAME /mnt/kerberos/

# Copy the nas cert and key
sudo mkdir -p /etc/ssl/localcerts
sudo cp /vagrant_templates/vagrant_nas-san.crt /etc/ssl/localcerts/vagrant_nas-san.crt
sudo cp /vagrant_templates/vagrant_nas-san.key /etc/ssl/localcerts/vagrant_nas-san.key

# setup LUN
sudo targetcli /backstores/block create san_disk_salle1 /dev/sdc
sudo targetcli /backstores/block create san_disk_salle2 /dev/sdd
sudo targetcli /iscsi create iqn.2026-08.com.san:vm.target1
sudo targetcli /iscsi create iqn.2026-08.com.san:vm.target2

sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/luns create /backstores/block/san_disk_salle1
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/luns create /backstores/block/san_disk_salle2

# We do not want an ACL to be automaticaly created for each initiator which log in
# Otherwise any initiator would have access
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1 set attribute generate_node_acls=0
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1 set attribute generate_node_acls=0
# targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/ get attribute
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/ set attribute authentication=1
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/ set attribute authentication=1

# ACL to give access to initiator
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/acls create iqn.2026-08.org.debian:01:8d75d0fb74e3
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/acls/iqn.2026-08.org.debian:01:8d75d0fb74e3 create 0 0
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/acls/iqn.2026-08.org.debian:01:8d75d0fb74e3/ set auth userid=donald
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/acls/iqn.2026-08.org.debian:01:8d75d0fb74e3/ set auth password=@pplepie94

sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/acls create iqn.2026-08.org.debian:01:8d75d0fb74e3
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/acls/iqn.2026-08.org.debian:01:8d75d0fb74e3 create 0 0
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/acls/iqn.2026-08.org.debian:01:8d75d0fb74e3/ set auth userid=donald
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/acls/iqn.2026-08.org.debian:01:8d75d0fb74e3/ set auth password=@pplepie94

sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/portals/ delete 0.0.0.0 3260
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/portals/ delete 0.0.0.0 3260

sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/portals/ create 192.168.1.203 3260
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target1/tpg1/portals/ create 192.168.2.203 3260
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/portals/ create 192.168.1.203 3260
sudo targetcli /iscsi/iqn.2026-08.com.san:vm.target2/tpg1/portals/ create 192.168.2.203 3260

sudo targetcli saveconfig
sudo systemctl enable --now targetclid.service


# Setup firewall
sudo firewall-cmd --add-service=nfs --permanent
sudo firewall-cmd --add-service=mountd --permanent
sudo firewall-cmd --add-service=rpc-bind --permanent
sudo firewall-cmd --add-port=25000/tcp --permanent
sudo firewall-cmd --add-port=25000/udp --permanent
sudo firewall-cmd --add-port=3260/tcp --permanent
sudo firewall-cmd --reload

# Set hostname
sudo hostnamectl set-hostname nas-san

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# Update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 nas-san.vagrant-dummy-ops.lab nas-san/' -i /etc/hosts
NAS_SAN_IPV4=$(ip -br -4 address show eth1 | grep -Eo '192.168.1.([0-9]{3})')
# We also add this so stunnel4 server will listen on host ipv4
echo "$NAS_SAN_IPV4 nas-san.vagrant-dummy-ops.lab" | sudo tee -a /etc/hosts

# umount vagrant sync folder
sudo umount /vagrant

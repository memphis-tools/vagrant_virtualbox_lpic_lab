#!/bin/bash

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install firewalld parted python3-pip lvm2 xfsprogs open-iscsi lsscsi multipath-tools multipath-tools-boot cryptsetup tcpdump python3.11-venv dsniff iputils-arping nmap tmux ettercap-text-only apache2 php-fpm apache2-utils

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 analyzer.vagrant-dummy-ops.lab analyzer/' -i /etc/hosts

# We set expected initiator name
sudo sed 's/^InitiatorName.*/InitiatorName=iqn.2026-08.org.debian:01:8d75d0fb74e3/' -i /etc/iscsi/initiatorname.iscsi

# sudo iscsiadm --mode discovery -type sendtargets -p 192.168.1.203:3260
# sudo iscsiadm --mode discovery -type sendtargets -p 192.168.2.203:3260
sudo iscsiadm --mode discovery -p 192.168.1.203 3260 -t st
sudo iscsiadm --mode discovery -p 192.168.2.203 3260 -t st

sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target1 -p 192.168.1.203 --op update --name node.session.auth.username --value=donald
sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target1 -p 192.168.1.203 --op update --name node.session.auth.password --value=@pplepie94
sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target1 -p 192.168.2.203 --op update --name node.session.auth.username --value=donald
sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target1 -p 192.168.2.203 --op update --name node.session.auth.password --value=@pplepie94

sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target2 -p 192.168.1.203 --op update --name node.session.auth.username --value=donald
sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target2 -p 192.168.1.203 --op update --name node.session.auth.password --value=@pplepie94
sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target2 -p 192.168.2.203 --op update --name node.session.auth.username --value=donald
sudo iscsiadm --mode node -T iqn.2026-08.com.san:vm.target2 -p 192.168.2.203 --op update --name node.session.auth.password --value=@pplepie94

sudo iscsiadm -m node -T iqn.2026-08.com.san:vm.target1 -p 192.168.1.203:3260 -o update -n node.startup -v automatic
sudo iscsiadm -m node -T iqn.2026-08.com.san:vm.target1 -p 192.168.2.203:3260 -o update -n node.startup -v automatic
sudo iscsiadm -m node -T iqn.2026-08.com.san:vm.target2 -p 192.168.1.203:3260 -o update -n node.startup -v automatic
sudo iscsiadm -m node -T iqn.2026-08.com.san:vm.target2 -p 192.168.2.203:3260 -o update -n node.startup -v automatic

sudo systemctl enable --now open-iscsi iscsid

# The systemd service will perform the login
# sudo iscsiadm --mode node --login --portal 192.168.1.203:3260 --targetname iqn.2026-08.com.san:vm.target1
# sudo iscsiadm --mode node --login --portal 192.168.2.203:3260 --targetname iqn.2026-08.com.san:vm.target1
# sudo iscsiadm --mode node --login --portal 192.168.1.203:3260 --targetname iqn.2026-08.com.san:vm.target2
# sudo iscsiadm --mode node --login --portal 192.168.2.203:3260 --targetname iqn.2026-08.com.san:vm.target2

# Inspect iscsi devices
sudo lsscsi -t

# Kill/Destroy/Logout
#sudo ls -la /sys/class/iscsi_session/*/device*/
#sudo iscsiadm --mode node --logoutall=all
#sudo iscsiadm --mode node --op delete

# Sleep sir
sleep 3

# Get the 2 unique WWIDs
mapfile -t WWIDS < <(
    ls -1 /dev/disk/by-id/scsi-* |
    sed 's#.*/scsi-##' |
    grep '^3600'
)

# Update the /etc/multipath/wwids
for wwid in "${WWIDS[@]}"; do
    multipath -a "$wwid"
done

WWID1="${WWIDS[0]}"
WWID2="${WWIDS[1]}"

# Create multipath.conf
sudo tee /etc/multipath.conf > /dev/null << EOF
defaults {
    find_multipaths no
    user_friendly_names no
}

blacklist {
    devnode "^sd[a]\$|^dm-"
}

devices {
    device {
        vendor "LIO-ORG"
        product "san_disk_*"
    }
}

multipaths {
    multipath {
        wwid "$WWID1"
        alias san_disk_salle1
    }
    multipath {
        wwid "$WWID2"
        alias san_disk_salle2
    }
}
EOF

# We reload and display paths
sudo multipath -r
sudo multipath -ll

# Setup the disks
sudo pvcreate /dev/mapper/san_disk_salle1
sudo pvcreate /dev/mapper/san_disk_salle2
sudo vgcreate vg_mirror_san_disk /dev/mapper/san_disk_salle1 /dev/mapper/san_disk_salle2
sudo lvcreate --type raid1 --mirrors 1 -n lv_mirror_san_disk vg_mirror_san_disk -L 900M

# Setup the encrypted volume to be mounted on ftp data folder
# Format the iscsi mirror disk partition 1 (unique, 1 disk == 1 partition)
sudo parted -s /dev/mapper/vg_mirror_san_disk-lv_mirror_san_disk mklabel msdos mkpart primary 1Mib 100%

# Luks format the created partition
# Reduce the Area offset in bytes where the keyslot data is stored int the LUKS header
# --pbkdf-memory: RAM usage controlled by the PBKDF memory cost (256000 bytes)
echo -n $LUKS_PASSPHRASE | sudo cryptsetup luksFormat --pbkdf-memory 256000 -q /dev/mapper/vg_mirror_san_disk-lv_mirror_san_disk1
# Generate a random LUKS key file and set appropriate perms
sudo dd if=/dev/urandom of=/root/.luks.key bs=1024 count=4
sudo chmod 0400 /root/.luks.key
# Add the random LUKS key to the luks partition
echo -n $LUKS_PASSPHRASE | sudo cryptsetup luksAddKey /dev/mapper/vg_mirror_san_disk-lv_mirror_san_disk1 /root/.luks.key --key-file -
# Open the encrypted partition with an associated label
sudo cryptsetup luksOpen /dev/mapper/vg_mirror_san_disk-lv_mirror_san_disk1 data_encrypted --key-file=/root/.luks.key

# Format the mounted encrypted partition with xfs for example
sudo mkfs.xfs /dev/mapper/data_encrypted
# Close the LUKS partition
sudo cryptsetup close /dev/mapper/data_encrypted

# Set the systemd service
sudo cp /vagrant_templates/luks-data.service /etc/systemd/system/
sudo cp /vagrant_templates/mnt-data_encrypted.mount /etc/systemd/system/
sudo cp /vagrant_templates/mnt-data_encrypted.automount /etc/systemd/system/

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable --now luks-data.service mnt-data_encrypted.automount mnt-data_encrypted.mount

# Set crypttab in case no "luks-data.service" used
#echo 'data_encrypted /dev/mapper/vg_mirror_san_disk-lv_mirror_san_disk1 /root/.luks.key luks' | tee -a /etc/crypttab

# Copy certificate and key pair files
sudo mkdir -p /etc/ssl/localcerts
sudo cp /vagrant_templates/vagrant_analyzer.crt /etc/ssl/localcerts/vagrant_analyzer.crt
sudo cp /vagrant_templates/vagrant_analyzer.key /etc/ssl/localcerts/vagrant_analyzer.key
sudo cp /vagrant_templates/vagrant_analyzer.crt /usr/local/share/ca-certificates/vagrant_analyzer.crt
sudo update-ca-certificates

sudo cp /vagrant_templates/index.php /var/www/html/index.php
sudo chown -R www-data: /var/www/html

# Setup apache webpage access
sudo htpasswd -cb /etc/apache2/.htpasswd admin $APACHE_PASSWORD_ACCESS
sudo chmod 0600 /etc/apache2/.htpasswd
sudo chown -R www-data: /etc/apache2/.htpasswd

# Setup apache logrotate
sudo cp /vagrant_templates/logrotate /etc/logrotate.d/apache2
sudo cp /vagrant_templates/logrotate.labs_data_encrypted /etc/logrotate.d/
(sudo crontab -l 2>/dev/null; echo "* * * * * /usr/sbin/logrotate /etc/logrotate.d/logrotate.labs_data_encrypted") | sudo crontab -
sudo systemctl restart logrotate.service

# Setup the global ServerName directive
echo 'ServerName analyzer.vagrant-dummy-ops.lab' | sudo tee -a '/etc/apache2/apache2.conf'

# Setup the virtualhost
sudo cp /vagrant_templates/dummy-analyzer.conf /etc/apache2/sites-available/dummy-analyzer.conf
sudo touch /mnt/data_encrypted/labs.log
sudo chown -R www-data: /mnt/data_encrypted/labs.log

# Setup apache
sudo a2enmod ssl proxy_fcgi setenvif
sudo a2dissite 000-default.conf
sudo a2ensite dummy-analyzer.conf
sudo rm /etc/apache2/sites-available/000-default.conf
sudo rm /etc/apache2/sites-available/default-ssl.conf
sudo rm /var/www/html/index.html
sudo systemctl restart apache2 php8.2-fpm

# Setup firewalld
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
firewall-cmd --add-port=514/tcp --permanent
firewall-cmd --add-port=514/udp --permanent
sudo firewall-cmd --reload

# Set hostname
sudo hostnamectl set-hostname analyzer

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# umount vagrant sync folder
sudo umount /vagrant

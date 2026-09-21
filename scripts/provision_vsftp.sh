#!/bin/bash

# Waiting for ansible playbooks to be set
sudo apt install -y parted xfsprogs auditd vsftpd cryptsetup libldap-common firewalld

# Set hostname
sudo hostnamectl set-hostname $HOSTNAME

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# Update /etc/hosts to map the hostname to localhost
sudo sed "/^127.0.0.1/s//127.0.0.1 $HOSTNAME.vagrant-dummy-ops.lab $HOSTNAME/" -i /etc/hosts

echo "192.168.1.200 dns1 dns1.vagrant-dummy-ops.lab" | sudo tee -a /etc/hosts
echo "192.168.1.201 dns2 dns2.vagrant-dummy-ops.lab" | sudo tee -a /etc/hosts
echo "192.168.1.210 squid.vagrant-dummy-ops.lab" | sudo tee -a /etc/hosts

# Copy vsftp key pair files
sudo cp /vagrant_templates/vagrant_vsftp.pem /etc/ssl/certs/vagrant_vsftp.pem
sudo cp /vagrant_templates/vagrant_vsftp.key /etc/ssl/private/vagrant_vsftp.key

# Copy vsftp conf file
sudo cp /vagrant_templates/vsftpd.conf /etc/vsftpd.conf

# Setup the encrypted volume to be mounted on ftp data folder
# Format the attached disk /dev/sdb is the default (we attach 1 disk)
sudo parted -s /dev/sdb mklabel msdos mkpart primary 1Mib 100%
# Luks format the created partition
# Reduce the Area offset in bytes where the keyslot data is stored int the LUKS header
# --pbkdf-memory: RAM usage controlled by the PBKDF memory cost (256000 bytes)
echo -n $LUKS_PASSPHRASE | sudo cryptsetup luksFormat --pbkdf-memory 256000 -q /dev/sdb1
# Generate a random LUKS key file and set appropriate perms
sudo dd if=/dev/urandom of=/root/.luks.key bs=1024 count=4
sudo chmod 0400 /root/.luks.key
# Add the random LUKS key to the luks partition
echo -n $LUKS_PASSPHRASE | sudo cryptsetup luksAddKey /dev/sdb1 /root/.luks.key --key-file -
# Open the encrypted partition with an associated label
sudo cryptsetup luksOpen /dev/sdb1 data_encrypted --key-file=/root/.luks.key

# Format the mounted encrypted partition with xfs for example
sudo mkfs.xfs /dev/mapper/data_encrypted
# Close the LUKS partition
sudo cryptsetup close /dev/mapper/data_encrypted

# Set the systemd service used for automount the ftp user's folder
sudo cp /vagrant_templates/data.mount /etc/systemd/system/
sudo cp /vagrant_templates/data.automount /etc/systemd/system/
sudo cp /vagrant_templates/luks-data.service /etc/systemd/system/

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable --now luks-data.service data.automount data.mount

# Set crypttab
echo 'data_encrypted /dev/sdb1 /root/.luks.key luks' | tee -a /etc/crypttab

# Set the vsftp service
# sudo mkdir /data
sudo useradd $DNS_MANAGER_USER_NAME -m -d /data/$DNS_MANAGER_USER_NAME -s /bin/bash
echo -e "${DNS_MANAGER_USER_PASSWORD}\n${DNS_MANAGER_USER_PASSWORD}" | sudo passwd $DNS_MANAGER_USER_NAME
unset DNS_MANAGER_USER_PASSWORD

sudo touch /etc/vsftpd.user_list
sudo chmod 0640 /etc/vsftpd.user_list
echo -e "$DNS_MANAGER_USER_NAME" | sudo tee /etc/vsftpd.user_list

# Set the firewall rules
# Learning process, we add the service, which is not used
sudo firewall-cmd --zone=public --add-service=ftp --permanent
# Since vsfpd is running in passive mode (see lftp -d ****) we choose random high port number
sudo firewall-cmd --zone=public --add-port=10000-10100/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart vsftpd

# umount vagrant sync folder
sudo umount /vagrant

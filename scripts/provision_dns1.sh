#!/bin/bash

sudo apt install -y bind9 bind9utils bind9-doc knot-dnsutils firewalld lftp libldap-common apparmor-utils

# Optionally update /etc/hosts to map the hostname to localhost
sudo sed '/^127.0.0.1/s//127.0.0.1 dns1.vagrant-dummy-ops.lab dns1/' -i /etc/hosts
echo '192.168.1.202 vsftp.vagrant-dummy-ops.lab' | sudo tee -a /etc/hosts

# Set the dns resolver
echo 'nameserver 192.168.1.200' | sudo tee /etc/resolv.conf
echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf
echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf

# Copy dns1 configuration templates
echo "Copying dns1 configuration files..."
sudo cp /vagrant_templates/named.conf.local /etc/bind/named.conf.local
sudo cp /vagrant_templates/named.conf.options /etc/bind/named.conf.options
sudo cp /vagrant_templates/db.vagrant-dummy-ops.lab /etc/bind/db.vagrant-dummy-ops.lab
sudo cp /vagrant_templates/db.1.168.192.in-addr.arpa /etc/bind/db.1.168.192.in-addr.arpa
sudo cp /vagrant_templates/vagrant_vsftp.crt /usr/local/share/ca-certificates/vagrant_vsftp.crt
sudo update-ca-certificates

sudo cp /vagrant_templates/vagrant_dovecot.crt /tmp/vagrant_dovecot.crt
sudo cp /vagrant_templates/vagrant_apache.crt /tmp/vagrant_apache.crt
# EXtract SPKI hash (3 1 1 expects SPKI hash), not the hash of the full certificate
#DOVECOT_TLSA_HASH=$(openssl x509 -in /tmp/vagrant_dovecot.crt -noout -sha256 -fingerprint | cut -d'=' -f2 | sed -e 's/://g')
DOVECOT_TLSA_HASH=$(openssl x509 -in /tmp/vagrant_dovecot.crt -noout -pubkey | openssl pkey -pubin -outform DER | openssl dgst -sha256 | cut -d'=' -f2 | tr -d ' ')
echo -e "_25._tcp.dovecot.vagrant-dummy-ops.lab. 3600 IN TLSA 3 1 1 $DOVECOT_TLSA_HASH" | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab
echo -e "_110._tcp.dovecot.vagrant-dummy-ops.lab. 3600 IN TLSA 3 1 1 $DOVECOT_TLSA_HASH" | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab
echo -e "_143._tcp.dovecot.vagrant-dummy-ops.lab. 3600 IN TLSA 3 1 1 $DOVECOT_TLSA_HASH" | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab
echo -e "_993._tcp.dovecot.vagrant-dummy-ops.lab. 3600 IN TLSA 3 1 1 $DOVECOT_TLSA_HASH" | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab
echo -e "_995._tcp.dovecot.vagrant-dummy-ops.lab. 3600 IN TLSA 3 1 1 $DOVECOT_TLSA_HASH" | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab
DOVECOT_TLSA_HASH=$(openssl x509 -in /tmp/vagrant_apache.crt -noout -pubkey | openssl pkey -pubin -outform DER | openssl dgst -sha256 | cut -d'=' -f2 | tr -d ' ')
echo -e "_443._tcp.apache.vagrant-dummy-ops.lab. 3600 IN TLSA 3 1 1 $DOVECOT_TLSA_HASH" | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab
# SMTP TLS Reporting (TLSRPT) standard, which is designed to let a mail domain publish a place where other mail servers can send reports about problems they encounter when trying to use TLS to deliver mail.
echo -e '_smtp._tls.dovecot.vagrant-dummy-ops.lab. 300 IN TXT "v=TLSRPTv1; rua=mailto:shijuro@dovecot.vagrant-dummy-ops.lab"' | sudo tee -a /etc/bind/db.vagrant-dummy-ops.lab

# We set the 'rw' perms on /etc/bind (that's why we use a copied apparmor file)
# Remember that apparmor enforced files and processes can be seen using: sudo aa-status
sudo cp /vagrant_templates/usr.sbin.named /etc/apparmor.d/usr.sbin.named
# We reload the conf to take effect
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.named

# Set TSIG (we use key named "transfer", used in the zone configuration files)
sudo tsig-keygen transfer > /etc/bind/tsig.key
echo 'include "/etc/bind/tsig.key";' | sudo tee -a '/etc/bind/named.conf'
# Upload the tsig.key file to the ftp server
lftp -u $DNS_MANAGER_USER_NAME,$DNS_MANAGER_USER_PASSWORD -e "set ftp:ssl-allow yes; set ssl:verify-certificate yes; put /etc/bind/tsig.key -o tsig.key; exit" ftp://vsftp.vagrant-dummy-ops.lab

# Set DNSSEC
sudo mkdir /etc/bind/keys
cd /etc/bind/keys
# Create the KSK keypair for zone vagrant-dummy-ops.lab
sudo dnssec-keygen -a RSASHA256 -b 2048 -n ZONE -f KSK vagrant-dummy-ops.lab
# Create the ZSK keypair for zone vagrant-dummy-ops.lab
sudo dnssec-keygen -a RSASHA256 -b 2048 -n ZONE vagrant-dummy-ops.lab
# Create the KSK keypair for zone vagrant-dummy-ops.lab
sudo dnssec-keygen -a RSASHA256 -b 2048 -n ZONE -f KSK 1.168.192.in-addr.arpa
# Create the ZSK keypair for zone vagrant-dummy-ops.lab
sudo dnssec-keygen -a RSASHA256 -b 2048 -n ZONE 1.168.192.in-addr.arpa

# Push the public keys on the ftp host
lftp -u $DNS_MANAGER_USER_NAME,$DNS_MANAGER_USER_PASSWORD -e "set ftp:ssl-allow yes; set ssl:verify-certificate yes; mput /etc/bind/keys/*.key; exit" ftp://vsftp.vagrant-dummy-ops.lab

# Append the public keys to zone files
# Notice that the include statement be used, but we could copy/past the public key
# Path to the zone file
ZONE_FILE_1="/etc/bind/db.vagrant-dummy-ops.lab"
ZONE_FILE_2="/etc/bind/db.1.168.192.in-addr.arpa"
# Path to the keys directory
KEYS_DIR="/etc/bind/keys"
# Find all .key files and loop through them
for key_file in $(find "$KEYS_DIR" -type f -iname 'Kvagrant*.key'); do
    # Extract the filename from the path (basename)
    key_filename=$(basename "$key_file")
    # Append $INCLUDE statement to the zone files
    echo "\$INCLUDE \"keys/$key_filename\"" >> "$ZONE_FILE_1"
done

# Find all .key files and loop through them
for key_file in $(find "$KEYS_DIR" -type f -iname 'K1*.key'); do
    # Extract the filename from the path (basename)
    key_filename=$(basename "$key_file")
    # Append $INCLUDE statement to the zone files
    echo "\$INCLUDE \"keys/$key_filename\"" >> "$ZONE_FILE_2"
done

# Notice setgid bit is set on /etc/bind (owner|group: root|bind)
sudo chown -R bind:bind /etc/bind

# Sign the zone files
# FROM MISTRAL AI: Since you're using inline-signing, BIND will sign the zone automatically when it loads. You don't need to run dnssec-signzone manually.
cd /etc/bind
echo "Signing zone files"
sudo dnssec-signzone -A -K /etc/bind/keys -3 $(head -c 1000 /dev/urandom | sha1sum | cut -b 1-16) -N increment -o vagrant-dummy-ops.lab -t /etc/bind/db.vagrant-dummy-ops.lab
sudo dnssec-signzone -A -K /etc/bind/keys -3 $(head -c 1000 /dev/urandom | sha1sum | cut -b 1-16) -N increment -o 1.168.192.in-addr.arpa -t /etc/bind/db.1.168.192.in-addr.arpa
echo "Zone files signed"

# Set hostname
sudo hostnamectl set-hostname dns1

# Set timezone
sudo timedatectl set-timezone Europe/Paris

# Update firewall rules
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload

sudo systemctl restart bind9

# umount vagrant sync folder
sudo umount /vagrant

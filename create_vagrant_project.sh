#!/bin/bash

set -eu

CYAN='\033[0;36m'
GREEN='\033[1;32m'
RESET='\033[0m'

echo -e "$CYAN[+] Source environment vars from .env file $RESET"
source .env
echo -e "$GREEN[+] File .env sourced $RESET"

echo -e "$CYAN[+] Trying to create the stack ssh keypairs $RESET"
# Create CA private key
openssl genpkey -out ./ephemeral-keys/vagrant_ca.key -algorithm RSA -aes256 -pass pass:$VAGRANT_CA_PASSWORD

# Create CA public key
openssl req -x509 -days 3650 \
  -key ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_ca.pem \
  -config ./openssl_cnf/vagrant_ca.cnf \
  -passin pass:$VAGRANT_CA_PASSWORD \
  -extensions v3_ca

# Create Ansible CA key pair
ssh-keygen -t rsa -b 4096 -f ./ephemeral-keys/vagrant_ansible_ca -N ""
# Create Ansible user key pair
ssh-keygen -t rsa -b 4096 -C "ansible@ansible.vagrant-dummy-ops.lab" -f ./ephemeral-keys/ansible_id_ed25519 -N $VAGRANT_ANSIBLE_PASSPHRASE
# Sign Ansible user public key
ssh-keygen -s ./ephemeral-keys/vagrant_ansible_ca -I ansible -n ansible -V +52w -z 1 ./ephemeral-keys/ansible_id_ed25519.pub
# Apply a passphrase to the SSH CA private key
ssh-keygen -p -f ./ephemeral-keys/vagrant_ansible_ca -P "" -N $VAGRANT_ANSIBLE_CA_PASSPHRASE


# Create a tomcat key
openssl genpkey -out ./ephemeral-keys/vagrant_tomcat.key -algorithm RSA

# Create a tomcat csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_tomcat.key \
  -out ./ephemeral-keys/vagrant_tomcat.csr \
  -config ./openssl_cnf/vagrant_tomcat.cnf

# Sign the tomcat csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_tomcat.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_tomcat.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_tomcat.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain tomcat crt
cat ./ephemeral-keys/vagrant_tomcat.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_tomcat_fullchain.pem

# Create a vsftp key
openssl genpkey -out ./ephemeral-keys/vagrant_vsftp.key -algorithm RSA

# Create a vsftp csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_vsftp.key \
  -out ./ephemeral-keys/vagrant_vsftp.csr \
  -config ./openssl_cnf/vagrant_vsftp.cnf

# Sign the vsftp csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_vsftp.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_vsftp.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_vsftp.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain vsftp crt
cat ./ephemeral-keys/vagrant_vsftp.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_vsftp_fullchain.pem

# Create a apache key
openssl genpkey -out ./ephemeral-keys/vagrant_apache.key -algorithm RSA

# Create a apache csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_apache.key \
  -out ./ephemeral-keys/vagrant_apache.csr \
  -config ./openssl_cnf/vagrant_apache.cnf

# Sign the apache csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_apache.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_apache.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_apache.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain apache crt
cat ./ephemeral-keys/vagrant_apache.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_apache_fullchain.pem

# Create a analyzer key
openssl genpkey -out ./ephemeral-keys/vagrant_analyzer.key -algorithm RSA

# Create a analyzer csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_analyzer.key \
  -out ./ephemeral-keys/vagrant_analyzer.csr \
  -config ./openssl_cnf/vagrant_analyzer.cnf

# Sign the analyzer csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_analyzer.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_analyzer.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_analyzer.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain analyzer crt
cat ./ephemeral-keys/vagrant_analyzer.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_analyzer_fullchain.pem

# Create a dovecot key
openssl genpkey -out ./ephemeral-keys/vagrant_dovecot.key -algorithm RSA

# Create a dovecot csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_dovecot.key \
  -out ./ephemeral-keys/vagrant_dovecot.csr \
  -config ./openssl_cnf/vagrant_dovecot.cnf

# Sign the dovecot csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_dovecot.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_dovecot.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_dovecot.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain dovecot crt
cat ./ephemeral-keys/vagrant_dovecot.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_dovecot_fullchain.pem

# Create a kdc key
openssl genpkey -out ./ephemeral-keys/vagrant_kdc.key -algorithm RSA

# Create a kdc csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_kdc.key \
  -out ./ephemeral-keys/vagrant_kdc.csr \
  -config ./openssl_cnf/vagrant_kdc.cnf

# Sign the kdc csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_kdc.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_kdc.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_kdc.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain kdc crt
cat ./ephemeral-keys/vagrant_kdc.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_kdc_fullchain.pem

# Create a openldap key
openssl genpkey -out ./ephemeral-keys/vagrant_openldap.key -algorithm RSA

# Create a openldap csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_openldap.key \
  -out ./ephemeral-keys/vagrant_openldap.csr \
  -config ./openssl_cnf/vagrant_openldap.cnf

# Sign the openldap csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_openldap.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_openldap.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_openldap.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain openldap crt
cat ./ephemeral-keys/vagrant_openldap.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_openldap_fullchain.pem

# Create a nslcd-client key
openssl genpkey -out ./ephemeral-keys/vagrant_nslcd-client.key -algorithm RSA

# Create a nslcd-client csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_nslcd-client.key \
  -out ./ephemeral-keys/vagrant_nslcd-client.csr \
  -config ./openssl_cnf/vagrant_nslcd-client.cnf

# Sign the nslcd-client csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_nslcd-client.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_nslcd-client.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_nslcd-client.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain nslcd-client crt
cat ./ephemeral-keys/vagrant_nslcd-client.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_nslcd-client_fullchain.pem

# Create a nas-san key
openssl genpkey -out ./ephemeral-keys/vagrant_nas-san.key -algorithm RSA

# Create a nas-san csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_nas-san.key \
  -out ./ephemeral-keys/vagrant_nas-san.csr \
  -config ./openssl_cnf/vagrant_nas-san.cnf

# Sign the nas-san csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_nas-san.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_nas-san.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_nas-san.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain nas-san crt
cat ./ephemeral-keys/vagrant_nas-san.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_nas-san_fullchain.pem

# Create a squid key
openssl genpkey -out ./ephemeral-keys/vagrant_squid.key -algorithm RSA -pkeyopt rsa_keygen_bits:4096

# Create a squid csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_squid.key \
  -out ./ephemeral-keys/vagrant_squid.csr \
  -config ./openssl_cnf/vagrant_squid.cnf

# Sign the squid csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_squid.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_squid.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_squid.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain squid crt
cat ./ephemeral-keys/vagrant_squid.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_squid_fullchain.pem

# Create a vagrant_squid_mitm_ca key
openssl genpkey -out ./ephemeral-keys/vagrant_squid_mitm_ca.key -algorithm RSA

# Create a vagrant_squid_mitm_ca csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_squid_mitm_ca.key \
  -out ./ephemeral-keys/vagrant_squid_mitm_ca.csr \
  -config ./openssl_cnf/vagrant_squid_mitm_ca.cnf

openssl x509 -req \
  -in ephemeral-keys/vagrant_squid_mitm_ca.csr \
  -CA ephemeral-keys/vagrant_ca.pem \
  -CAkey ephemeral-keys/vagrant_ca.key \
  -CAcreateserial \
  -out ephemeral-keys/vagrant_squid_mitm_ca.pem \
  -days 1825 \
  -sha256 \
  -extfile ./openssl_cnf/vagrant_squid_mitm_ca.cnf \
  -extensions v3_ca \
  -passin pass:$VAGRANT_CA_PASSWORD


# Create a nginx key
openssl genpkey -out ./ephemeral-keys/vagrant_nginx.key -algorithm RSA

# Create a nginx csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_nginx.key \
  -out ./ephemeral-keys/vagrant_nginx.csr \
  -config ./openssl_cnf/vagrant_nginx.cnf

# Sign the nginx csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_nginx.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_nginx.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_nginx.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain nginx crt
cat ./ephemeral-keys/vagrant_nginx.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_nginx_fullchain.pem

# Create a openvpn key
openssl genpkey -out ./ephemeral-keys/vagrant_openvpn-server.key -algorithm RSA -aes256 -pass pass:$OPENVPN_SERVER_PASSPHRASE

# Create a openvpn csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_openvpn-server.key \
  -out ./ephemeral-keys/vagrant_openvpn-server.csr \
  -config ./openssl_cnf/vagrant_openvpn-server.cnf \
  -passin pass:$OPENVPN_SERVER_PASSPHRASE

# Sign the openvpn csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_openvpn-server.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_openvpn-server.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_openvpn-server.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain openvpn crt
cat ./ephemeral-keys/vagrant_openvpn-server.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_openvpn-server_fullchain.pem

# Create a openvpn-client key
openssl genpkey -out ./ephemeral-keys/vagrant_openvpn-client.key -algorithm RSA

# Create a openvpn-client csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_openvpn-client.key \
  -out ./ephemeral-keys/vagrant_openvpn-client.csr \
  -config ./openssl_cnf/vagrant_openvpn-client.cnf

# Sign the openvpn-client csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_openvpn-client.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_openvpn-client.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_openvpn-client.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a fullchain openvpn-client crt
cat ./ephemeral-keys/vagrant_openvpn-client.pem ./ephemeral-keys/vagrant_ca.pem > ./ephemeral-keys/vagrant_openvpn-client_fullchain.pem

# Create a squid-stunnel4-server key
openssl genpkey -out ./ephemeral-keys/vagrant_squid-stunnel4-server.key -algorithm RSA

# Create a squid-stunnel4-server csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_squid-stunnel4-server.key \
  -out ./ephemeral-keys/vagrant_squid-stunnel4-server.csr \
  -config ./openssl_cnf/vagrant_squid-stunnel4-server.cnf

# Sign the squid-stunnel4-server csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_squid-stunnel4-server.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_squid-stunnel4-server.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_squid-stunnel4-server.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD


  # Create a bastion key
  openssl genpkey -out ./ephemeral-keys/vagrant_bastion.key -algorithm RSA

  # Create a bastion csr
  openssl req -new \
    -key ./ephemeral-keys/vagrant_bastion.key \
    -out ./ephemeral-keys/vagrant_bastion.csr \
    -config ./openssl_cnf/vagrant_bastion.cnf

  # Sign the bastion csr
  openssl x509 -req \
    -in ./ephemeral-keys/vagrant_bastion.csr \
    -CA ./ephemeral-keys/vagrant_ca.pem \
    -CAkey ./ephemeral-keys/vagrant_ca.key \
    -out ./ephemeral-keys/vagrant_bastion.pem \
    -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_bastion.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD

# Create a stunnel4-client key
openssl genpkey -out ./ephemeral-keys/vagrant_stunnel4-client.key -algorithm RSA

# Create a stunnel4-client csr
openssl req -new \
  -key ./ephemeral-keys/vagrant_stunnel4-client.key \
  -out ./ephemeral-keys/vagrant_stunnel4-client.csr \
  -config ./openssl_cnf/vagrant_stunnel4-client.cnf

# Sign the stunnel4-client csr
openssl x509 -req \
  -in ./ephemeral-keys/vagrant_stunnel4-client.csr \
  -CA ./ephemeral-keys/vagrant_ca.pem \
  -CAkey ./ephemeral-keys/vagrant_ca.key \
  -out ./ephemeral-keys/vagrant_stunnel4-client.pem \
  -days 3650 -sha256 -extfile ./openssl_cnf/vagrant_stunnel4-client.cnf -extensions req_ext -passin pass:$VAGRANT_CA_PASSWORD


echo -e "$GREEN[+] Stack ssh keypairs created $RESET"

echo -e "$CYAN[+] Trying to create the tomcat keystore $RESET"
# create a PKCS12 (.p12) keystore from the tomcat webapp's x509 cert
openssl pkcs12 -export \
  -name ./tomcat \
  -in ./ephemeral-keys/vagrant_tomcat.pem \
  -inkey ./ephemeral-keys/vagrant_tomcat.key \
  -certfile ./ephemeral-keys/vagrant_ca.pem \
  -out ./ephemeral-keys/vagrant_tomcat.p12 \
  -password pass:$VAGRANT_TOMCAT_KEYSTORE_PASSWORD
echo -e "$GREEN[+] Tomcat keystore created $RESET"

echo -e "$CYAN[+] Trying to create the DH 2048 bit file for squid and openvpn $RESET"
openssl dhparam -out ./templates/squid/squid.dhparam.pem 2048
openssl dhparam -out ./templates/openvpn/dh2048.pem 2048
echo -e "$GREEN[+] DH 2048 bit file created $RESET"

echo -e "$CYAN[+] Trying to setup tomcat templates $RESET"
cp ./ephemeral-keys/vagrant_tomcat.pem ./templates/tomcat/vagrant_tomcat.crt
cp ./ephemeral-keys/vagrant_tomcat.key ./templates/tomcat/vagrant_tomcat.key
cp ./ephemeral-keys/vagrant_tomcat.p12 ./templates/tomcat
cp ./ephemeral-keys/vagrant_tomcat_fullchain.pem ./templates/tomcat
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup vsftp templates $RESET"
cp ./ephemeral-keys/vagrant_vsftp.pem ./templates/dns1/vagrant_vsftp.crt
cp ./ephemeral-keys/vagrant_vsftp.pem ./templates/dns2/vagrant_vsftp.crt
cp ./ephemeral-keys/vagrant_vsftp.pem ./templates/vsftp/vagrant_vsftp.pem
cp ./ephemeral-keys/vagrant_vsftp.key ./templates/vsftp/vagrant_vsftp.key
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup analyzer templates $RESET"
cp ./ephemeral-keys/vagrant_analyzer.pem ./templates/analyzer/vagrant_analyzer.crt
cp ./ephemeral-keys/vagrant_analyzer.key ./templates/analyzer/vagrant_analyzer.key
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup apache templates $RESET"
cp ./ephemeral-keys/vagrant_apache.pem ./templates/apache/vagrant_apache.crt
cp ./ephemeral-keys/vagrant_apache.key ./templates/apache/vagrant_apache.key
cp ./ephemeral-keys/vagrant_apache_fullchain.pem ./templates/apache/vagrant_apache_fullchain.crt
cp ./ephemeral-keys/vagrant_dovecot.pem ./templates/dovecot/vagrant_dovecot.crt
cp ./ephemeral-keys/vagrant_apache.pem ./templates/dns1/vagrant_apache.crt
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup dovecot templates $RESET"
cp ./ephemeral-keys/vagrant_dovecot.pem ./templates/dovecot/vagrant_dovecot.crt
cp ./ephemeral-keys/vagrant_dovecot.key ./templates/dovecot/vagrant_dovecot.key
cp ./ephemeral-keys/vagrant_dovecot_fullchain.pem ./templates/dovecot/vagrant_dovecot_fullchain.crt
cp ./ephemeral-keys/vagrant_dovecot.pem ./templates/dns1/vagrant_dovecot.crt
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup kdc templates $RESET"
cp ./ephemeral-keys/vagrant_kdc.pem ./templates/kdc/vagrant_kdc.crt
cp ./ephemeral-keys/vagrant_kdc.key ./templates/kdc/vagrant_kdc.key
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup openldap ansible roles and templates $RESET"
cp ./ephemeral-keys/vagrant_openldap.pem ./ansible/roles/install_openldap/files/vagrant_openldap.crt
cp ./ephemeral-keys/vagrant_openldap.key ./ansible/roles/install_openldap/files/vagrant_openldap.key
cp ./ephemeral-keys/vagrant_openldap.pem ./templates/openldap/vagrant_openldap.crt
cp ./ephemeral-keys/vagrant_openldap.key ./templates/openldap/vagrant_openldap.key
echo -e "$GREEN[+] Templates and ansible roles updated updated $RESET"

echo -e "$CYAN[+] Trying to setup nas-san templates $RESET"
cp ./ephemeral-keys/vagrant_nas-san.pem ./templates/nas-san/vagrant_nas-san.crt
cp ./ephemeral-keys/vagrant_nas-san.key ./templates/nas-san/vagrant_nas-san.key
cp ./ephemeral-keys/vagrant_nas-san_fullchain.pem ./templates/nas-san/vagrant_nas-san_fullchain.crt
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup squid templates $RESET"
cp ./ephemeral-keys/vagrant_squid.pem ./templates/squid/vagrant_squid.crt
cp ./ephemeral-keys/vagrant_squid.key ./templates/squid/vagrant_squid.key
cp ./ephemeral-keys/vagrant_squid_mitm_ca.pem ./templates/squid/vagrant_squid_mitm_ca.crt
cp ./ephemeral-keys/vagrant_squid_mitm_ca.key ./templates/squid/vagrant_squid_mitm_ca.key
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup nginx templates $RESET"
cp ./ephemeral-keys/vagrant_nginx.pem ./templates/nginx/vagrant_nginx.crt
cp ./ephemeral-keys/vagrant_nginx.key ./templates/nginx/vagrant_nginx.key
cp ./ephemeral-keys/vagrant_nginx_fullchain.pem ./templates/nginx/vagrant_nginx_fullchain.crt
cp ./ephemeral-keys/vagrant_dovecot.pem ./templates/nginx/vagrant_dovecot.crt
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup openvpn server ansible roles $RESET"
cp ./ephemeral-keys/vagrant_openvpn-server.pem ./ansible/roles/install_openvpn/files/vagrant_openvpn-server.crt
cp ./ephemeral-keys/vagrant_openvpn-server.key ./ansible/roles/install_openvpn/files/vagrant_openvpn-server.key
cp ./ephemeral-keys/vagrant_openvpn-server_fullchain.pem ./ansible/roles/install_openvpn/files/vagrant_openvpn-server_fullchain.crt
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup openvpn client ansible roles $RESET"
cp ./ephemeral-keys/vagrant_openvpn-client.pem ./ansible/roles/install_openvpn/files/vagrant_openvpn-client.crt
cp ./ephemeral-keys/vagrant_openvpn-client.key ./ansible/roles/install_openvpn/files/vagrant_openvpn-client.key
cp ./ephemeral-keys/vagrant_openvpn-client_fullchain.pem ./ansible/roles/install_openvpn/files/vagrant_openvpn-client_fullchain.crt
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup nslcd ansible roles $RESET"
cp ./ephemeral-keys/vagrant_nslcd-client.pem ansible/roles/install_nslcd_client/files/vagrant_nslcd-client.crt
cp ./ephemeral-keys/vagrant_nslcd-client.key ansible/roles/install_nslcd_client/files/vagrant_nslcd-client.key
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to setup trust CA ansible roles $RESET"
cp ./ephemeral-keys/vagrant_ca.pem ansible/roles/trust_ca/files/vagrant_ca.crt
echo -e "$GREEN[+] Ansible roles updated $RESET"

echo -e "$CYAN[+] Trying to copy SSH CA public key into ansible roles $RESET"
cp ./ephemeral-keys/vagrant_ansible_ca.pub ansible/roles/install_ansible_user/files/vagrant_ansible_ca.pub
cp ./ephemeral-keys/vagrant_ansible_ca.pub ansible/roles/install_ansible_controller/files/vagrant_ansible_ca.pub
echo -e "$GREEN[+] Ansible roles updated $RESET"

echo -e "$CYAN[+] Trying to copy ansible SSH CA private key into ansible roles $RESET"
cp ./ephemeral-keys/vagrant_ansible_ca ansible/roles/install_bastion_pubkey_signer/files/vagrant_ansible_ca
echo -e "$GREEN[+] Ansible roles updated $RESET"

echo -e "$CYAN[+] Trying to copy ansible user ssh-keypair files into ansible roles $RESET"
cp ./ephemeral-keys/ansible_id_ed25519-cert.pub ansible/roles/install_ansible_user/files/ansible_id_ed25519-cert.pub
cp ./ephemeral-keys/ansible_id_ed25519 ansible/roles/install_ansible_user/files/ansible_id_ed25519
cp ./ephemeral-keys/ansible_id_ed25519-cert.pub ansible/roles/install_ansible_controller/files/ansible_id_ed25519-cert.pub
cp ./ephemeral-keys/ansible_id_ed25519 ansible/roles/install_ansible_controller/files/ansible_id_ed25519
echo -e "$GREEN[+] Ansible roles updated $RESET"

echo -e "$CYAN[+] Trying to setup bastion templates $RESET"
cp ./ephemeral-keys/vagrant_bastion.pem ./templates/bastion/vagrant_bastion.crt
cp ./ephemeral-keys/vagrant_bastion.key ./templates/bastion/vagrant_bastion.key
echo -e "$GREEN[+] Templates updated $RESET"

echo -e "$CYAN[+] Trying to copy stunnel4 (client and server) certificates into ansible roles $RESET"
cp ./ephemeral-keys/vagrant_squid-stunnel4-server.pem ansible/roles/install_squid_stunnel4_server/files/vagrant_squid-stunnel4-server.crt
cp ./ephemeral-keys/vagrant_squid-stunnel4-server.key ansible/roles/install_squid_stunnel4_server/files/vagrant_squid-stunnel4-server.key
cp ./ephemeral-keys/vagrant_stunnel4-client.pem ansible/roles/install_stunnel4_client/files/vagrant_stunnel4-client.crt
cp ./ephemeral-keys/vagrant_stunnel4-client.key ansible/roles/install_stunnel4_client/files/vagrant_stunnel4-client.key
echo -e "$GREEN[+] Ansible roles updated $RESET"

echo -e "$CYAN[+] Create vagrant VM's $RESET"
#vagrant up --no-parallel
echo -e "$CYAN[+] Vagrant VM's created $RESET"

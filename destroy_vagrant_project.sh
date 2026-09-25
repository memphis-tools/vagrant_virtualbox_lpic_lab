#!/bin/bash

set -e

CYAN='\033[0;36m'
GREEN='\033[1;32m'
WHITE='\033[1;97m'
RESET='\033[0m'

echo -e "$CYAN[+] Source environment vars from .env file $RESET"
source .env
echo -e "$GREEN[+] File .env sourced $RESET"

echo -e "$CYAN[+] Trying to destroy vagrant VM's $RESET"
#vagrant destroy -f
echo -e "$CYAN[+] Vagrant VM's destroyed $RESET"

echo -e "$CYAN[+] Trying to remove any .crt .key .pem .pub, files $RESET"
rm -f ./ephemeral-keys/*
find . -iname '*.crt' -exec rm -f {} \;
find . -iname '*.key' -exec rm -f {} \;
find . -iname '*.pem' -exec rm -f {} \;
find . -iname '*.pub' -exec rm -f {} \;
find . -iname '*.p12' -exec rm -f {} \;
find . -iname '*.keystore' -exec rm -f {} \;
find . -iname '*.truststore' -exec rm -f {} \;
echo -e "$GREEN[+] ./ephemeral-keys/* files removed $RESET"

echo -e "$CYAN[+] Trying to remove any .vagrant/ folder $RESET"
rm -rf .vagrant/
echo -e "$GREEN[+] Folder .vagrant/ removed $RESET"

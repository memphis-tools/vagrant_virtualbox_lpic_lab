#!/bin/bash

#set -eu

RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[0;36m"
RESET="\033[0m"

# In case user calls script with args, we use a subset, otherwise we get all the ipv4 records from the lab
HOSTS_SUBSET=("$@")
HOSTS=()
IPS=()

# scan_dns_domain_records
# Description: get all ipv4 records from the lab dns. We update HOSTS and IPS addresses
scan_dns_domain_records() {
  for IPV4 in $(dig vagrant-dummy-ops.lab +short); do
    short_hostname=$(dig -x $IPV4 +short | cut -d '.' -f1)
    HOSTS+=("$short_hostname")
    IPS+=("$IPV4")
  done
}

# purge_known_hosts_keys
purge_known_hosts_keys() {
  echo "" > ~/.ssh/known_hosts
}

# scan_hosts_keys
scan_hosts_keys() {
  for ((i=0;i<${#HOSTS[@]};i++))
  do
    HOST_KEY="$(ssh-keyscan -t ed25519 ${HOSTS[i]}.vagrant-dummy-ops.lab 2>/dev/null)"
    HOST_IP_KEY="$(ssh-keyscan -t ed25519 ${IPS[i]} 2>/dev/null)"
    if [[ $HOST_KEY == "" ]] && [[ $HOST_IP_KEY == "" ]]; then
      echo -e "$RED[INFO] Unknow or not running host ${HOSTS[i]} $RESET"
      continue
    fi
    echo -e "$HOST_KEY" >> ~/.ssh/known_hosts
    echo -e "$HOST_IP_KEY" >> ~/.ssh/known_hosts
    echo -e "$GREEN[INFO] ~/.ssh/known_hosts updated for ${IPS[i]} ${HOSTS[i]}.vagrant-dummy-ops.lab $RESET"
  done
}

# scan_hosts_keys_subset
scan_hosts_keys_subset() {
  for ((i=0;i<${#HOSTS_SUBSET[@]};i++)); do
    FOUND=false
    for ((j=0;j<${#HOSTS[@]};j++)); do
      if [[ ${HOSTS_SUBSET[i]} == ${HOSTS[j]} ]]; then
        HOST_KEY="$(ssh-keyscan -t ed25519 ${HOSTS[j]}.vagrant-dummy-ops.lab 2>/dev/null)"
        HOST_IP_KEY="$(ssh-keyscan -t ed25519 ${IPS[j]} 2>/dev/null)"
        sed "/^${HOSTS[j]}.vagrant-dummy-ops.lab/d" -i ~/.ssh/known_hosts
        echo -e "$HOST_KEY" >> ~/.ssh/known_hosts
        sed "/^${IPS[j]}/d" -i ~/.ssh/known_hosts
        echo -e "$HOST_IP_KEY" >> ~/.ssh/known_hosts
        FOUND=true
        echo -e "$GREEN[INFO] ~/.ssh/known_hosts updated for ${IPS[j]} ${HOSTS[j]}.vagrant-dummy-ops.lab $RESET"
        break
      fi
    done
    if [[ $FOUND == "false" ]]; then
      echo -e "$RED[INFO] Unknow or not running host ${HOSTS_SUBSET[i]} $RESET"
    fi
  done
}

scan_dns_domain_records

if [[ "${#HOSTS_SUBSET[@]}" -gt 0 ]]; then
  scan_hosts_keys_subset
else
  purge_known_hosts_keys
  scan_hosts_keys
fi

# Remove any blank lines from ~/.ssh/known_hosts
sed "/^$/d" -i ~/.ssh/known_hosts
echo -e "$GREEN[INFO] ~/.ssh/known_hosts any blank lines removed $RESET"

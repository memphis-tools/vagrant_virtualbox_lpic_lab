#!/bin/bash

set -eu

for USER in $(ls /home); do
  if [[ $USER != 'ansible' ]] && [[ $USER != 'vagrant' ]]; then
    if [[ -f /home/$USER/.ssh/id_ed25519.pub ]]; then
       ssh-keygen -p -f /root/vagrant_ansible_ca -P "$(cat /root/passphrase)" -N ""
       ssh-keygen -s /root/vagrant_ansible_ca -I $USER -n $USER -V +12h -z 1 /home/$USER/.ssh/id_ed25519.pub
       ssh-keygen -p -f /root/vagrant_ansible_ca -P "" -N "$(cat /root/passphrase)"
       chown -R $USER: /home/$USER/.ssh
    fi
  fi
done

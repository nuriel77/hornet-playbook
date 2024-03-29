#!/usr/bin/env bash

cd /opt/hornet-playbook
git pull origin main
ansible-playbook -i inventory site.yml -e overwrite=yes --tags=vhosts_config -v

read -p "Done updating MQTT nginx configuration. Please press ENTER to continue."

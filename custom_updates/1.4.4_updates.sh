#!/usr/bin/env bash

cd /opt/hornet-playbook
git pull origin main
ansible-playbook -i inventory site.yml -e overwrite=yes --tags=hornet_config_file -v

read -p "Done updating Hornet configuration file. Please press ENTER to continue."

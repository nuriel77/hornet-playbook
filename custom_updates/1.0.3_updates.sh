#!/usr/bin/env bash

cd /opt/hornet-playbook
git pull origin main
ansible-playbook -i inventory site.yml -e overwrite=yes --tags=nginx_role -v

read -p "Done updating API restrictions on nginx and added db d/l feature on horc. Please press ENTER to continue."

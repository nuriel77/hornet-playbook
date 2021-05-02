#!/usr/bin/env bash

cd /opt/hornet-playbook
git pull origin main
ansible-playbook -i inventory site.yml -e overwrite=yes --tags=nginx_role -v

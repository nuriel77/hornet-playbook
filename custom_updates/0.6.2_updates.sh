#!/bin/bash
set -e

cd /opt/hornet-playbook
git pull

echo "Update config.json for HORNET 0.5.0"
ansible-playbook -i inventory site.yml -v --tags=hornet_config_file -e overwrite=yes

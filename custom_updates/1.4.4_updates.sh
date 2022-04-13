#!/usr/bin/env bash
set -e

cd /opt/hornet-playbook
git pull origin main

echo "Stopping hornet..."
/bin/systemctl stop hornet || true

echo "Deleting participation DB..."
rm -rf /var/lib/hornet/mainnetdb/participation
ansible-playbook -i inventory site.yml -e overwrite=yes --tags=hornet_config_file -v

echo "Ensure hornet is started..."
/bin/systemctl start hornet || true
read -p "Done updating Hornet configuration file. Please press ENTER to continue."

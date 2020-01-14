#!/usr/bin/env bash

cat <<EOF

************************* Important Notice *************************

Hornet 0.3.0 has introduced breaking changes in config.json.

For details, please visit https://github.com/gohornet/hornet/releases/tag/v0.3.0


This update is going to save the current '/var/lib/hornet/config.json' to '/var/lib/hornet/config.json.0.3.3.old' and apply the new config.json.

EOF

read -p "Press [Enter] key to proceed with the update..."

cp -- /var/lib/hornet/config.json /var/lib/hornet/config.json.0.3.3.old

cd /opt/hornet-playbook
ansible-playbook -i inventory site.yml -v --tags=hornet_config_files -e overwrite=yes

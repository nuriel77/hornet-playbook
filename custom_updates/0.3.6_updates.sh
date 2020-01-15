#!/usr/bin/env bash
set -e

echo "Ensure latest playbook ..."
cd /opt/hornet-playbook && git pull

echo "Stopping hornet for uid/gid change ..."
/bin/systemctl stop hornet

echo "Changing uid/gid for hornet to match docker image ..."
usermod -u 39999 hornet || true
groupmod -g 39999 hornet || true
mkdir -p /var/lib/hornet/snapshot
[ -f /var/lib/hornet/latest-export.gz.bin ] && mv -- /var/lib/hornet/latest-export.gz.bin /var/lib/hornet/snapshot/.
chown hornet:hornet /var/lib/hornet -R

echo "Set new path for latest-export.gz.bin ..."
sed -i 's#"path": "latest-export.gz.bin"#"path": "snapshot/latest-export.gz.bin"#' /var/lib/hornet/config.json

echo "Run hornet role ..."
ansible-playbook -i inventory site.yml -v --tags=hornet_role

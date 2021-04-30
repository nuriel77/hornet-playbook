#!/usr/bin/env bash
set -e

cd /opt/hornet-playbook
git pull origin main

if [ ! -f "roles/haproxy/tasks/main.yml" ]
then
    echo "No haproxy role to remove, all done."
    exit
fi

echo "Removing haproxy dependency"
ansible-playbook site.yml \
  -i inventory \
  -v \
  -e uninstall_playbook=true \
  --tags=uninstall_loadbalancer

echo "Updating playbook"
cp /var/lib/hornet/peering.json ~/.
ansible-playbook site.yml \
  -i inventory \
  -v \
  -e overwrite=yes \
  --skip-tags=loadbalancer_role
\cp ~/peering.json /var/lib/hornet/peering.json

read -p "There were some major changes in this update: The Dashboard, Grafana, Prometheus and Alertmanager are reachable on the browser on the paths: /, /grafana, /prometheus and /alertmanager respectfully."

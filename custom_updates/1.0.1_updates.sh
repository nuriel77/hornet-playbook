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

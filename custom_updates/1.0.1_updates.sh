#!/usr/bin/env bash
set -e

cd /opt/hornet-playbook
git pull origin main

echo "Removing haproxy dependency"
ansible-playbook site.yml \
  -i inventory \
  -v \
  -e uninstall_playbook=true \
  --tags=uninstall_loadbalancer

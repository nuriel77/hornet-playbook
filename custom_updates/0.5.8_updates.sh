#!/usr/bin/env bash
set -e

echo "Updating /etc/haproxy/haproxy.cfg to allow GET /healthz."
echo "A backup file will be made for the configuration if you need to restore anything from it."

cd /opt/hornet-playbook
git pull
ansible-playbook -i inventory site.yml -v -e overwrite=yes --tags=loadbalancer_role

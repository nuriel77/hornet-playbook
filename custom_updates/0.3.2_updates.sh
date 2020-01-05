#!/usr/bin/env bash
set -e
cd /opt/hornet-playbook
ansible-playbook -i inventory site.yml -v --tags=scripts -e overwrite=yes

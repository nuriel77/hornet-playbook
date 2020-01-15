#!/usr/bin/env bash

cd /opt/hornet-playbook
ansible-playbook -i inventory site.yml -v --tags=hornet_role

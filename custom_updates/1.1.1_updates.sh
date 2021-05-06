#!/usr/bin/env bash

cd /opt/hornet-playbook
git pull origin main
run-playbook --tags=nginx_role

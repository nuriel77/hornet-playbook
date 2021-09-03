#!/usr/bin/env bash
set -e

run-playbook --tags=hornet_config_file,hornet_firewalld,hornet_ufw -e overwrite=yes

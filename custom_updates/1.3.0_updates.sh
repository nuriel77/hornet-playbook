#!/usr/bin/env bash
set -e

echo "Updating hornet.conf to apply new Max DB Size feature ..."
run-playbook --tags=hornet_config_file -e overwrite=yes

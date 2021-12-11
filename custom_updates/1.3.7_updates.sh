#!/usr/bin/env bash
set -e

run-playbook --tags=hornet_config_file,vhosts_config -e overwrite=yes

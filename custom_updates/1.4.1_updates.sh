#!/usr/bin/env bash
set -e

run-playbook --tags=nginx_role -e overwrite=yes

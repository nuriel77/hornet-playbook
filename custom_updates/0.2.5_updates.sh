#!/usr/bin/env bash

cd /opt/hornet-playbook && git pull && ansible-playbook -i inventory site.yml --tags=local_deps

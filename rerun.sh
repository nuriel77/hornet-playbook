#!/bin/bash
:>/etc/motd
cd /opt/hornet-playbook && SKIP_CONFIRM="true" bash fullnode_install.sh rerun

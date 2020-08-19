#!/usr/bin/env bash
set -e

if [ -e /etc/default/hornet ]
then
    CONFIG_FILE="/etc/default/hornet"
elif [ -e /etc/sysconfig/hornet ]
then
    CONFIG_FILE="/etc/sysconfig/hornet"
fi

if grep -q overwriteCooAddress "$CONFIG_FILE"
then
    echo "Already updated"
    exit
fi

sed -i 's|^OPTIONS="\(.*\)"|OPTIONS="\1 --overwriteCooAddress"|' "$CONFIG_FILE"

echo "Restarting HORNET with new COO address overwrite ..."
systemctl restart hornet

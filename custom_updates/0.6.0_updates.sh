#!/usr/bin/env bash
set -e

if grep -q overwriteCooAddress /etc/default/hornet
then
    echo "Already updated"
    exit
fi

sed -i 's|^OPTIONS="\(.*\)"|OPTIONS="\1 --overwriteCooAddress"|' /etc/default/hornet

echo "Restarting HORNET with new COO address overwrite ..."
systemctl restart hornet

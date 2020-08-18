#!/usr/bin/env bash
set -e

if grep -q UDYXTZBE9GZGPM9SSQV9LTZNDLJIZMPUVVXYXFYVBLIEUHLSEWFTKZZLXYRHHWVQV9MNNX9KZC9D9UZWZ /etc/default/hornet
then
    echo "Already updated"
    exit
fi

sed -i 's|^OPTIONS="\(.*\)"|OPTIONS="\1 --overwriteCooAddress UDYXTZBE9GZGPM9SSQV9LTZNDLJIZMPUVVXYXFYVBLIEUHLSEWFTKZZLXYRHHWVQV9MNNX9KZC9D9UZWZ"|' /etc/default/hornet

echo "Restarting HORNET with new COO address overwrite ..."
systemctl restart hornet

#!/bin/bash
set -e

if grep -q downloadURLs "/var/lib/hornet/config.json"
then
    echo "Update to config file already applied."
    exit
fi

# Update to change the downloadURL key to a list of sources. See https://github.com/gohornet/hornet/pull/568
cp -- "/var/lib/hornet/config.json" "/tmp/config.json.$$"
sed  -i 's/downloadURL/downloadURLs/' "/tmp/config.json.$$"

jq '.snapshots.local.downloadURLs = ["https://ls.manapotion.io/export.bin","https://x-vps.com/export.bin","https://dbfiles.iota.org/mainnet/hornet/latest-export.bin"]' "/tmp/config.json.$$" > "/tmp/config.json.final.$$"
mv -- "/tmp/config.json.final.$$" "/var/lib/hornet/config.json"
rm -f "/tmp/config.json.$$"
echo "Restarting Hornet to apply new changes..."
/bin/systemctl restart hornet

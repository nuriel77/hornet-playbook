#!/usr/bin/env bash
set -e

if grep -q "ba6d07d1a1aea969e7e435f9f7d1b736ea9e0fcb8de400bf855dba7f2a57e947" /var/lib/hornet/config.json
then
    echo "Key already exists in /var/lib/hornet/config.json. Nothing to update."
    exit
fi

TMP_FILE=$(mktemp /tmp/config.json.XXXXXX)

jq -r '.protocol.publicKeyRanges[2] |= .+ {"end": 2108160, "key": "ba6d07d1a1aea969e7e435f9f7d1b736ea9e0fcb8de400bf855dba7f2a57e947", "start": 552960}' < /var/lib/hornet/config.json > "$TMP_FILE"

if jq -e . < "$TMP_FILE" >/dev/null
then
    mv "$TMP_FILE" /var/lib/hornet/config.json
    chown hornet:hornet /var/lib/hornet/config.json
    chmod 600 /var/lib/hornet/config.json
    echo "Restarting Hornet ..."
    /bin/systemctl restart hornet
fi

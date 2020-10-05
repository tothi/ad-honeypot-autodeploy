#!/bin/bash
#

echo "[*] Running packers..."
packer build -timestamp-ui -var-file private.json win2016.json &
packer build -timestamp-ui -var-file private.json win10.json &
packer build -timestamp-ui -var-file private.json graylog.json &

wait

echo "[+] All of the builds have been completed."

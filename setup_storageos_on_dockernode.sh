#!/bin/bash

modprobe nbd nbds_max=1024

grep nbd /etc/modules > /dev/null 2>&1
   if [ $? -ge 1 ]; then
       echo "nbd" >> /etc/modules
   fi

grep "options nbd nbds_max" /etc/modprobe.d/nbd.conf > /dev/null 2>&1
   if [ $? -ge 1 ]; then
       echo "options nbd nbds_max=1024" >> /etc/modprobe.d/nbd.conf
   fi

docker plugin install --alias storageos --grant-all-permissions storageos/plugin KV_ADDR=${HOSTNAME}:8500

curl -sSL https://github.com/storageos/go-cli/releases/download/0.0.10/storageos_linux_amd64 > /usr/local/bin/storageos && chmod +x /usr/local/bin/storageos

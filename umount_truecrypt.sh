#!/bin/bash
sync
sync
sync
echo "Unmounting Truecrypt volumes..."
truecrypt -d
echo " done!\n"
sleep 5
exit 0

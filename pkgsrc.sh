#!/bin/bash

query=$1

echo "Searching in installed packages..."
ls /var/log/packages/ | grep -i $query

echo
sudo slackpkg search $query

echo
sudo sbopkg -g $query

exit 0


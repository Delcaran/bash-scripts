#!/bin/bash

# Definizioni dei virus
#freshclam

LOG=`sudo /usr/sbin/slackpkg check-updates`
if [ "$?" != 0 ]; then
	echo "Error checking updates...Wait until next try."
elif echo $LOG | grep "News on ChangeLog.txt" &> /dev/null ; then
	sudo /usr/sbin/slackpkg update
else
	echo "No slackpkg updates."
fi

# Repository SlackBuilds.org
sudo /usr/sbin/sbopkg -r

# Queue files per SlackBuilds.org
if [ "$1" != "fast" ]; then
	sudo /usr/sbin/sqg -a
fi

exit 0

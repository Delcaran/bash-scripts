#!/bin/bash

# Definizioni dei virus
freshclam

LOG=`/usr/sbin/slackpkg check-updates`
if [ "$?" != 0 ]; then
	echo "Error checking updates...Wait until next try."
elif echo $LOG | grep "News on ChangeLog.txt" &> /dev/null ; then
	/usr/sbin/slackpkg update
else
	echo "No slackpkg updates."
fi

# Repository SlackBuilds.org
sbopkg -r

# Queue files per SlackBuilds.org
if [ "$1" != "fast" ]; then
	sqg -a
fi

exit 0

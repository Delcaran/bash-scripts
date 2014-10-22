#!/bin/sh
RESULT=$(slackpkg check-updates)
if [[ "$RESULT" != "No news is good news" ]]
then
    slackpkg update
fi
sbopkg -r
sqg -a
exit 0

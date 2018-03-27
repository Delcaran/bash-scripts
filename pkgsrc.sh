#!/bin/bash

query=$1

sudo slackpkg search $query
sudo sbopkg -g $query

exit 0


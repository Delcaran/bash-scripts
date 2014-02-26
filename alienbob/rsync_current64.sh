#!/bin/sh
# $Id: rsync_current.sh,v 1.4 2005/09/11 14:13:23 root Exp root $
# -----------------------------------------------------------------------------
# Use rsync to mirror a Slackware directory tree.
# The default is to make a mirror of slackware-current, but you can alter that
# by running the script like this:
#
#   VERSION=10.1 rsync_current.sh
#
# ...which will mirror Slackware-10.1 instead.
# Also, all the parameters that you pass this script will be appended to the
# rsync command line, so if you want to do a 'dry-run', i.e. want to look at
# what the rsync would do without actually downloading/deleting anything, add
# the '-n' parameter to the script like this:
#
#   rsync_current.sh -n
#
# -----------------------------------------------------------------------------
# Author: Eric Hameleers <alien at slackware.com> :: 11sep2005
# -----------------------------------------------------------------------------
#
VERSION=${VERSION:-current}
TOPDIR="/home/delcaran/REPOSITORY/"
RSYNCURL="slackware.mirrors.tds.net::slackware"

echo "Syncing version '$VERSION' ..."

if [ ! -d ${TOPDIR}/slackware64-$VERSION ]; then
  echo "Target directory ${TOPDIR}/slackware64-$VERSION does not exist!"
  exit 1
fi

cd ${TOPDIR}/slackware64-$VERSION
rsync $1 -vaz --delete --progress --exclude "pasture/*" ${RSYNCURL}/slackware64-$VERSION/ .


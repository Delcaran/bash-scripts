#!/bin/sh
# $Id: burnt_iso_md5_check.sh,v 1.1 2008/03/22 16:51:22 root Exp root $
# Written 2008 by Eric Hameleers <alien@slackware.com>
#
# This command will check the md5sum of a cd (ignoring possible padding at
# the end by only checking the same amount of bytes at the iso image) and
# also check the md5sum of the ISO image.
# Idea found at:
# http://www.linuxquestions.org/questions/showthread.php?p=3077366#post3077366
# and expanded a bit.
#

if [ $1 ]; then
  isoFile=$1
else
  echo "Usage: $0 <iso-image> <cd-drive>"
  echo "E.g.   $0  /tmp/slackware-12.0.iso /dev/dvd"
  exit 1
fi

if [ $2 ]; then
  cdDrive=$2
else
  echo "Usage: $0 <iso-image> <cd-drive>"
  echo "E.g.   $0  /tmp/slackware-12.0.iso /dev/dvd"
  exit 1
fi

if [ ! -b $cdDrive ]; then
  echo "ERROR.  '$cdDrive' is not a block device."
  exit 1
fi

if [ ! -r $isoFile ]; then
  echo "ERROR.  ISO image '$isoFile' does not exist."
  exit 1
else
  echo "** Verifying md5sums between $isoFile <-> $cdDrive"
  dd if=$cdDrive | head -c $(stat --format=%s $isoFile) | md5sum \
    && md5sum $isoFile
fi


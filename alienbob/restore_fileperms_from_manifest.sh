#!/bin/bash
# Copyright 2005, 2006  CTSMacon LLC., Macon, GA, USA
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Howdy folks!
#
# Some one on IRC had their box completely hosed due to someone running a
#   "chmod -R 777 /" like a newb, so I banged up this script to fix it.
# Hope y'all enjoy.

# Alan Hicks

# ----------------------------------------------------------------------------
# This script will restore all default permissions on a Slackware box
# This may work with other UNIXs as well, but you'll need a file
# in the same way as a massaged MANIFEST file in Slackware

# You MUST have a file called MANIFEST in the directory you are calling
# this script from that contains a list of all the files you want
# changed and their correct permissions and ownership.  This is easily
# done in Slackware by removing all lines that begin with "+" or "|"
# in the file.
#
# The following works fine on Slackware.
#
# bunzip2 MANIFEST.bz2
# mv MANIFEST file
# egrep "^[d-]" file > MANIFEST

(while read line; do

  # Tag the filename
  PATH_NAME="$( echo $line | awk '{print $6}' )"

  # Tag the permissions
  FULL_PERM="$(echo $line | cut -c 2-10 )"
  OWNER_GROUP="$( echo $line | awk '{print $2}' | sed -e s+/+:+ )"

  OWN_PERMS="$(echo $FULL_PERM | cut -c 1-3 )"
  GROUP_PERMS="$(echo $FULL_PERM | cut -c 4-6 )"
  ALL_PERMS="$(echo $FULL_PERM | cut -c 7-9 )"

  # Read in owner permissions (and the suid bit!)
  if [ "$( echo $OWN_PERMS | cut -c 1)" = "r" ]; then
    READ=4
  else
    READ=0
  fi
  if [ "$( echo $OWN_PERMS | cut -c 2)" = "w" ]; then
    WRITE=2
  else
    WRITE=0
  fi
  if [ "$( echo $OWN_PERMS | cut -c 3)" = "x" ]; then
    EXE=1
  else
    EXE=0
  fi
  if [ "$( echo $OWN_PERMS | cut -c 3)" = "s" ]; then
    SUID=4
    EXE=1
  else
    SUID=0
    EXE=0
  fi

OWN=$(( $READ + $WRITE + $EXE ))

  # Read in group permissions (and the sgid bit!)
  if [ "$( echo $GROUP_PERMS | cut -c 1)" = "r" ]; then
    READ=4
  else
    READ=0
  fi
  if [ "$( echo $GROUP_PERMS | cut -c 2)" = "w" ]; then
    WRITE=2
  else
    WRITE=0
  fi
  if [ "$( echo $GROUP_PERMS | cut -c 3)" = "x" ]; then
    EXE=1
  else
    EXE=0
  fi
  if [ "$( echo $GROUP_PERMS | cut -c 3)" = "s" ]; then
    EXE=1
    SGID=2
  else
    SGID=0
    EXE=0
  fi

GROUP=$(( $READ + $WRITE + $EXE ))

  # Read in world permissions (and the sticky bit!)
  if [ "$( echo $ALL_PERMS | cut -c 1)" = "r" ]; then
    READ=4
  else
    READ=0
  fi
  if [ "$( echo $ALL_PERMS | cut -c 2)" = "w" ]; then
    WRITE=2
  else
    WRITE=0
  fi
  if [ "$( echo $ALL_PERMS | cut -c 3)" = "x" ]; then
    EXE=1
  else
    EXE=0
  fi
  if [ "$( echo $ALL_PERMS | cut -c 3)" = "t" ]; then
    STICKY=1
    EXE=1
  else
    STICKY=0
    EXE=0
  fi

ALL=$(( $READ + $WRITE + $EXE ))

OTHER=$(( $SUID + $SUID + $STICKY ))

echo chmod -R $OTHER$OWN$GROUP$ALL /$PATH_NAME
echo chgrp $OWNER_GROUP /$PATH_NAME

done) < MANIFEST



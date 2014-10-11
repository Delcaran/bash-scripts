#/bin/sh
# $Id: extract_initramfs.sh,v 1.5 2007/05/31 16:17:32 root Exp root $
# ----------------------------------------------------------------------------
# Purpose:
#   Create or extract initramfs archives.
# Usage:
#   extract_initramfs <archivename> <target_directory>
#   create_initramfs <archivename> <source_directory>
#
# Author:
#   Eric Hameleers <alien@slackware.com>
#
# ----------------------------------------------------------------------------

# My paranoia:
set -e
# Debugging:
#set -x

# Names by which the script can be called (use symlinks for this!):
EXTRACT_NAME=extract_initramfs.sh
CREATE_NAME=create_initramfs.sh

usage() {
cat <<EOT__

$0 :
   Create or extract initramfs archives.
Usage:
   extract_initramfs <archivename> <target_directory>
   create_initramfs <archivename> <source_directory>
NOTE:
   The target directory will be created if it does not yet exist.
   The initramfs contents will be extracted to this target directory.
   The target directory's existing contents will *not* be erased
    prior to extracting the initramfs, in case the directory already exists.

EOT__
}

if [ -z "$1" ]; then
  usage
  exit 1
else
  INITRD=$1
  [ "${INITRD:0:1}" != "/" ] && INITRD=$(pwd)/${INITRD}
fi

if [ -z "$2" ]; then
  usage
  exit 2
else
  DIR=$2
fi


if [ "`basename $0`" = "${EXTRACT_NAME}" ]; then
  if [ ! -r ${INITRD} ]; then
    echo "***ERROR*** Can not read initramfs file '${INITRD}'!"
    exit 11
  fi
  if [ ! -d ${DIR} ]; then
    # Try to create the target directory:
    if ! mkdir -p ${DIR} ; then
      echo "***ERROR*** Can not create directory '${DIR}'!"
      exit 11
    fi
  fi
  cd ${DIR}
  echo "--- Extracting the initramfs into the directory '${DIR}'"
  gunzip -cd ${INITRD} | cpio -i -d -H newc --no-absolute-filenames
elif [ "`basename $0`" = "${CREATE_NAME}" ]; then
  if [ ! -d ${DIR} ]; then
    echo "***ERROR*** Directory '${DIR}' does not exist!"
    exit 12
  fi
  # Gzip the initrd (this is a cpio archive for the 2.6 kernel's initramfs):
  cd ${DIR}
  echo "--- Creating the initramfs from content below '${DIR}'"
  find . | cpio -o -H newc | gzip -9 > ${INITRD}
  RET=$?
  [ $RET -ne 0 ] && echo "An error occured in creating $INITRD (code $RET)"
fi


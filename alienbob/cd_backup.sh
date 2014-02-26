#!/bin/sh
# $Id: cd_backup.sh,v 1.6 2007/06/04 08:29:56 root Exp root $
# ---------------------------------------------------------------------------
# Write the contents of a directory to CD/RW on-the-fly:
# A CD/RW medium is supposed to be in the drive, it will be blanked first.
# If the drive tray is open, it will be closed first.
#
# The script uses the 'buffer' program if available, to minimize glitches
# in the data stream piped into cdrecord. This is useful for old cdwriters
# that have no burnfree capabilities.
#
# Eric Hameleers <alien@slackware.com>
# ---------------------------------------------------------------------------

# Adapt for your writer hardware:
CDDEV="0,0,0"                # determine this with with 'cdrecord -scanbus'
DRIVER_OPTS="burnfree"       # options for the driver for your writer
SPEED=8                      # CD writing speed

# A 700MB medium is common, change if you have another medium capacity:
CDSIZE=700                   # Size in MB of the CD medium used

# ---------------------------------------------------------------------------
# There should be no need to change anything below this point.
# ---------------------------------------------------------------------------

THE_DATE=`date +%Y%m%d_%H%M`
ME=`basename $0`

if [ "$1" == "" ]; then
  echo "*** Usage: $ME <directory>"
  exit 1
fi

if [ ! -d $1 ]; then
  echo "*** Argument '$1' should be a directory."
  exit 1
fi

# First, umount the CD. If that fails, we won't continue.
echo "*** Checking if we should unmount the CD first..."
OUTPUT=`umount /mnt/cdrom 2>&1`
RES=$?
if ! [ $RES -eq 0 ] && ! echo $OUTPUT | grep -q "not mounted"; then
  echo "*** Could not unmount the mounted CD medium. Aborting now..".
  exit 1
else
  echo "*** Ready to continue."
fi

ROOM=$(( ${CDSIZE}*1024*1024/10**6 -30 ))
DIRSIZE=`du -sm $1`
DIRSIZE=`echo $DIRSIZE | cut -f1 -d' '`
echo "*** Backing up '$1' with $DIRSIZE MB of data."

if [ $DIRSIZE -gt $ROOM ]; then
  echo "----------------------------------------------------------------------"
  echo "*** WARNING ***"
  echo "    The calculated size of directory tree '$1' is ${DIRSIZE} MB..." 
  echo "    which is too large to fit onto a $CDSIZE MB medium."
  echo "    You might have an error while burning the CD."
  echo ""
  echo "    Exiting now..."
  echo "----------------------------------------------------------------------"
  exit 1
fi

# Open and close the tray:
echo "*** Closing the CD tray if needed..."
cdrecord -eject dev=${CDDEV} 1>/dev/null
cdrecord -load dev=${CDDEV} 1>/dev/null

# Check if the CD medium is already empty:
echo "*** [`date`]"
echo -n "*** [$ME]: Checking if CD is empty..."
RES=$( cdrecord -toc dev=${CDDEV} 2>&1 | grep 'Cannot read TOC' )
if [ -n "$RES" ]; then
  echo " cannot read TOC, assuming empty."
else
  # Blank the CD/RW first:
  echo " not empty."
  echo "*** [`date`]"
  echo "*** [$ME]: Blanking the CD first..."
  #cdrecord dev=${CDDEV} blank=all gracetime=2 1>/dev/null
  cdrecord dev=${CDDEV} blank=fast gracetime=2 1>/dev/null
  RES=$?
  if [ $RES -ne 0 ]; then
    echo "*** [`date`]"
    echo "*** [$ME]: Blanking ended with return code '$RES'"
    echo "*** Aborting the backup now; please check the CD medium in the drive."
    exit 1
  fi
fi

# Write the contents of <directory> immediately to CD, on-the-fly:
echo "*** [`date`]"
echo "*** [$ME]: Starting to write contents of '$1' to the CD/RW:"

if [ -x `which buffer` ]; then
  # Use the 'buffer' program to better guarantee a continuous stream
  # of data into cdrecord.
  mkisofs -R -J -N -V "DOOR_BACKUP_${THE_DATE}" -p "Eric Hameleers" \
          -d -hide-rr-moved --quiet "$1" | \
      buffer -s 512k -m 2m |  \
      cdrecord -data speed=${SPEED} dev=${CDDEV} gracetime=2 \
          driveropts=${DRIVER_OPTS} -
  RES=$?
else
  mkisofs -R -J -N -V "DOOR_BACKUP_${THE_DATE}" -p "Eric Hameleers" \
          -d -hide-rr-moved --quiet "$1" | \
      cdrecord -data speed=${SPEED} dev=${CDDEV} gracetime=2 \
          driveropts=${DRIVER_OPTS} -
  RES=$?
fi

echo "*** [`date`]"
echo "*** [$ME]: Writing the CD/RW finished with return code '$RES'."

exit 0

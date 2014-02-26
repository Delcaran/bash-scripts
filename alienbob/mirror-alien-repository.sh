#!/bin/sh
# $Id: mirror-alien-repository.sh,v 1.1 2008/03/15 15:15:05 root Exp root $
# Written 2008 Eric Hameleers <alien@slackware.com>, Eindhoven, Netherlands
#
# Mirror the http://www.slackware.com/~alien/slackbuilds repository.
# Since the repository allows only http transfers, use lftp instead of rsync.
# Don't use 'wget' because that does not delete remote files when they
# disappear on the remote server.
#
#  The script works by downloading a copy of the remote ChangeLog.txt and then
#  comparing it to your local version of this file. If no differences
#  are found, the script will stop right there.
#  If differences are found, the script will show the 'diff' output and then
#  continue to mirror the remote repository. By using lftp, this process will
#  be relatively efficient.
#  When you want to run this script in a cron job, be sure to filter out STDERR
#  so that you will only see emails from cron when there is actually a change.
#  Example cron entry if you put the script in /usr/local/bin :
#  30 6 * * *      /usr/local/bin/mirror-alien-repository.sh 2>/dev/null
#
# ---------------------------------------------------------------------------

# Do we want more messages? A '1' means 'yes', a '0' means 'no'.
DEBUG=${DEBUG:-0}

# We prevent the mirror script from running more than one instance:
PIDFILE=/var/tmp/$(basename $0 .sh).pid

# Make sure the PID file is removed when we kill the process
trap 'rm -f $PIDFILE; exit 1' TERM INT

if [ -e $PIDFILE ]; then
  echo "Another instance (`cat $PIDFILE`) still running?"
  echo "If you are sure that no other instance is running, delete the lockfile"
  echo "'${PIDFILE}' and re-start this script."
  echo "Aborting now..."
  exit 1
else
  echo $$ > $PIDFILE
fi

# Our local mirror:
LOCALTREE=${LOCALTREE:-"/tmp/alien_repository"}
# The URL for the remote repository:
REMOTEURL=${REMOTEURL:-"http://www.slackware.com/~alien/slackbuilds"}
# Where we store temporary files if needed:
TMP=${TMP:-"/tmp"}
# Tools:
LFTP=${LFTP:-"/usr/bin/lftp"}

# Sanity checks:
if [ ! -d $TMP  ]; then
  echo "Temp directory '$TMP' does not exist yet, creating directory now..."
  mkdir -p $TMP
fi

if [ ! -w $TMP  ]; then
  echo "Temp directory '$TMP' is not writable! Quitting now..."
  rm -f $PIDFILE
  exit 1
fi

if [ ! -d $LOCALTREE  ]; then
  echo "Local tree '$LOCALTREE' does not exist yet, creating directory now..."
  mkdir -p $LOCALTREE
fi

if [ ! -w $LOCALTREE  ]; then
  echo "Local tree '$LOCALTREE' is not writable! Aborting..."
  rm -f $PIDFILE
  exit 1
fi

# Check for an updated ChangeLog.txt:
[ $DEBUG -eq 1 ] && echo "$(date) [$$]: Getting ChangeLog.txt..."
rm -f $TMP/alien_ChangeLog.txt
cd $TMP
# Direct all output to stderr so that you can filter it out in a cron job:
$LFTP -e "get ChangeLog.txt -o alien_ChangeLog.txt && quit" $REMOTEURL 1>&2
cd -
if [ ! -s $TMP/alien_ChangeLog.txt ]; then
  echo "$(date) [$$]: Could not retrieve ChangeLog.txt! Aborting..."
  rm -f $PIDFILE
  exit 1
fi

# If the ChangeLog.txt on our local mirror doesn't exist, it might mean that
# this is a first-time mirror. To prevent the script from aborting, we
# create an empty ChangeLog.txt file...
if [ ! -e ${LOCALTREE}/ChangeLog.txt ]; then
  touch ${LOCALTREE}/ChangeLog.txt
fi

diff -b ${LOCALTREE}/ChangeLog.txt $TMP/alien_ChangeLog.txt
STATUS="$?"
if [ "$STATUS" == "2" ]; then
  echo "$(date) [$$]: Trouble when running diff, aborting..."
  rm -f $PIDFILE
  exit 1
elif [ "$STATUS" == 0 ]; then
  [ $DEBUG == 1 ] && echo "$(date) [$$]: No difference found, quitting now..."
  rm -f $PIDFILE
  exit 0
else
  echo "$(date) [$$]: ChangeLog.txt has been updated."
fi

# Starting the mirror:
echo "$(date) [$$]: Starting the mirroring process."
# Direct all output to stderr so that you can filter it out in a cron job:
lftp -c "open $REMOTEURL ; mirror --verbose=0 --delete --continue . $LOCALTREE/" 1>&2
echo "$(date) [$$]: Finished the mirroring process."

rm -f $PIDFILE

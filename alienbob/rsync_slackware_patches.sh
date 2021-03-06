#!/bin/sh
# $Id: rsync_slackware_patches.sh,v 1.21 2013/05/04 18:43:13 root Exp root $
#-----------------------------------------------------------------------------
# Program name:
#   rsync_slackware_patches.sh
# Purpose:
#   Keep the /patches tree for a Slackware release in sync with a master
#   server. See the output of the "rsync_slackware_patches.sh -h" command
#   for the available command-line switches.
#   The patches will be stored in $SLACKTREE/$SLACKDIR-$VERSION/patches/
# Author:
#   Eric Hameleers <alien@slackware.com>
#-----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Configurable options
# ---------------------------------------------------------------------------


# Where do we store the downloaded patches in our local filesystem?
# This location can be overridden on the commandline by setting it as an
# environment variable, like this:
# "SLACKTREE=/home/myslack ./rsync_slackware_patches.sh"
SLACKTREE=${SLACKTREE:-"/home/ftp/pub/Linux/Slackware"}

# The release we're getting the patches for (override with "-r" option)
# By default, use the version reported by '/etc/slackware-version':
SLACKDEF=$(cat /etc/slackware-version |cut -d' ' -f2 |cut -d. -f1-2)

# What architecture will we be mirroring? The default is 'x86' meaning 32bit.
# Alternatively you can specify 'x86_64' meaning 64bit. The value of SARCH
# determines the name of the slackware directories.
# This value can be overruled via the '-a' commandline parameter;
SARCH=${SARCH:-"x86"}

# Do we want to see progress reports?
# (override on the commandline using the "-q" option,
# to be silent unless there is an update to download)
VERBOSE=1

# By default we maintain an exact mirror. If you want to keep old packages
# after they have been deleted from the remote server, use the '-k' or "keep"
# parameter to keep these old files (or set the KEEPOPTS="" below).
KEEPOPTS="--delete --delete-excluded"

# We do not want to download packages only - get the sources too!
# Override with the "-p" commandline option if you want the script to
# only download packages (i.e. no sources - saves bandwidth):
PKGONLY=0

# You can use an 'excludes' file that contains items to exclude from
# the rsync; one exclude per line. For example, create a file excl_12.txt
# with the lines (get rid of the '#   ' of course!):
#   patches/packages/kde*
#   patches/packages/amarok*
# and set the line below to EXCLUDEFILE="/path/to/excl_12.txt"
EXCLUDEFILE=""

# What do we use as the master server?
# Some good mirrors are:
#   rsync.osuosl.org::slackware
#   slackware.mirrors.tds.net::slackware
#   rsync.slackware.no::slackware
RSYNCHOST=${RSYNCHOST:-"slackware.mirrors.tds.net::slackware"}

# ---- end of configurable options -------------------------------------------

BN=$(basename $0)
SHOWHELP=0

while getopts "a:hknpr:qX:" Option
do
  case $Option in
    a ) SARCH=${OPTARG}
        ;;
    h ) SHOWHELP=1
        ;;
    k ) KEEPOPTS=" "
        ;;
    n ) echo "[$BN:] Performing a dry-run!" ; RSYNCOPTS="${RSYNCOPTS} -n"
        ;;
    p ) echo "[$BN:] Not downloading sources, only packages!" ; PKGONLY=1
        ;;
    r ) VERSION=${OPTARG}
        ;;
    q ) VERBOSE=0
        ;;
    X ) EXCLUDEFILE="$(cd $(dirname $OPTARG); pwd)/$(basename $OPTARG)"
        ;;
    * ) ;;   # DEFAULT
  esac
done

# End of option parsing.
shift $(($OPTIND - 1))

#  $1 now references the first non option item supplied on the command line
#  if one exists.

# Set some values early, to be used in the help output:
VERSION=${VERSION:-${SLACKDEF}}
[ "$SARCH" = "x86_64" ] && SLACKDIR="slackware64" || SLACKDIR="slackware" 

if [ $SHOWHELP -eq 1 ]; then
  cat <<-"EOH"
	-----------------------------------------------------------------
	$Id: rsync_slackware_patches.sh,v 1.21 2013/05/04 18:43:13 root Exp root $
	-----------------------------------------------------------------
	EOH
  echo "[$BN:] Parameters are:"
  echo "  -a <arch>    Architecture to mirror (defaults to 'x86',"
  echo "               can be 'x86_64' too)."
  echo "  -h           This help."
  echo "  -k           Keep old local files even though they were"
  echo "               removed on the remote server."
  echo "  -n           Rsync dry-run (don't download anything)."
  echo "  -p           Download packages only - not the sources."
  echo "  -r <release> Act on Slackware version <release>. The default"
  echo "               is to download patches for Slackware ${SLACKDEF}"
  echo "  -q           Non-verbose output (for cron jobs)."
  echo "  -X <xfile>   File 'xfile' contains a list of exclude patterns"
  echo "               for packages that you do not want mirrored."
  echo ""
  echo "Our master rsync server: '${RSYNCHOST}'."
  echo "Your local mirror: '${SLACKTREE}/$SLACKDIR-$VERSION'"
  exit
fi

[ ${VERBOSE} -eq 1 ] && RSYNCVERBOSE="-v --progress" || RSYNCVERBOSE="-q"

[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Syncing patches for ${SLACKDIR} version '${VERSION}'."

if [ ! -d ${SLACKTREE}/${SLACKDIR}-${VERSION}/patches ]; then
  echo "[$BN:] Target directory ${SLACKTREE}/${SLACKDIR}-${VERSION}/patches does not exist!"
  echo "[$BN:] Please create it first, and then re-run this script."
  exit 1
fi

[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Changing to '${SLACKTREE}/$SLACKDIR-$VERSION/'."

cd ${SLACKTREE}/$SLACKDIR-$VERSION/

# Exclude the sources if requested:
[ $PKGONLY -eq 1 ] && RSYNCOPTS="$RSYNCOPTS --exclude=patches/source"

# Use an excludes file if provided:
if [ "$EXCLUDEFILE" != "" ]; then
  if [ -f "$EXCLUDEFILE" ]; then
    [ ${VERBOSE} -eq 1 ] && \
       echo "[$BN:] Excluding files found in '$EXCLUDEFILE'"
    RSYNCOPTS="$RSYNCOPTS --exclude-from=$EXCLUDEFILE"
  fi
fi

# Record time of last modification of CHECKSUMS.md5 (it might not yet be there!)
LASTMOD=$(stat -c %Y ./patches/CHECKSUMS.md5 2>/dev/null)
LASTMOD=${LASTMOD:-0}

# Keep a copy of ChangeLog.txt for feedback in case of updates:
TMPFILE=$(mktemp /tmp/ChangeLog.XXXXXX)
TMPFILE=${TMPFILE:-/tmp/ChangeLog.txt.$$}
cat ChangeLog.txt > $TMPFILE 2>/dev/null

[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Here we go... using master '${RSYNCHOST}'"

rsync ${RSYNCOPTS} ${RSYNCVERBOSE} -a --delete ${RSYNCHOST}/$SLACKDIR-$VERSION/ChangeLog.txt .
rsync ${RSYNCOPTS} ${RSYNCVERBOSE} -a --delete ${RSYNCHOST}/$SLACKDIR-$VERSION/FILELIST.TXT .
rsync ${RSYNCOPTS} ${RSYNCVERBOSE} -a --delete ${RSYNCHOST}/$SLACKDIR-$VERSION/CHECKSUMS.md5* .
rsync ${RSYNCOPTS} ${RSYNCVERBOSE} -a ${KEEPOPTS} ${RSYNCHOST}/$SLACKDIR-$VERSION/patches .

[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Exit status: $?"
[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Done rsync-ing."

# Compare time of last modification of the CHECKSUMS.md5 to what we had:
NEWMOD=$(stat -c %Y ./patches/CHECKSUMS.md5)
NEWMOD=${NEWMOD:-0}

if [ $LASTMOD -ne $NEWMOD ]; then
  echo "[$BN:] New patches have arrived for Slackware ${VERSION} ($SARCH)!"
  echo
  echo "......................................................................."
  echo
  diff $TMPFILE ChangeLog.txt
elif [ ${VERBOSE} -eq 1 ]; then
  echo "[$BN:] No change detected in the CHECKSUMS.md5 file."
fi

# Clean up:
[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Removing temporary file '$TMPFILE'."
rm -f $TMPFILE

[ ${VERBOSE} -eq 1 ] && echo "[$BN:] Done!"

exit 0

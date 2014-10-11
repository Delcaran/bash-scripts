#!/bin/sh
# Copyright 2007-2009  Eric Hameleers, Eindhoven, NL
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
# ---------------------------------------------------------------------------
# Description:
#     Generate the .asc files (gpg signatures) for a series of tarballs,
#     by default those in the SlackBuilds.org repository.
# Author:
#    Eric Hameleers <alien@slackware.com>
# ---------------------------------------------------------------------------
cat <<"EOT"

# -------------------------------------------------------------------#
# $Id: sbo_gpgsign.sh,v 1.16 2011/02/09 18:39:38 root Exp root $ #
# -------------------------------------------------------------------#

EOT

# The directory of the Slackware package repository (you can re-define the
# variable REPOSROOT on the commandline so you won't have to change the script):
REPOSROOT=${REPOSROOT:-"/mnt/ssh/slackbuilds.org/www/slackbuilds/"}

# Repository maintainer's GPG key:
REPOSKEY=${REPOSKEY:-"9C7BA3B6"} # default to "SlackBuilds.org Development Team"

# Force re-creation of all .asc files:
# You can enable this by passing the "-a" parameter to the script.
FORCEASC="no"

# Check existing .asc files and regenerate those that do not verify.
# You can also enable this by passing the "-f" (for "fix") parameter.
CHECKASC="no"

# As a courtesy, allow the script to generate md5sums too.
ADDMD5="no"

# The files to sign end on '.tar.gz' - only look for those.
# You can change this also by passing "-e <ext>" to the script.
FEXT="tar.gz"

# Debug output? The "-v" parameter enables verbose output.
DEBUG=0

# Dry run? I.e. only check but do not (re)generate signatures?
DRYRUN="no"

# Either use gpg or gpg2:
GPGBIN=${GPGBIN:-"/usr/bin/gpg"}

# Optionally use gpg-agent to cache the gpg passphrase instead of letting the
# script keep it in the environment (note that if you define USE_GPGAGENT=1
# but gpg-agent is not running, you will get prompted for a passphrase every
# single time gpg runs):
USE_GPGAGENT=${USE_GPGAGENT:-0}

# Command line parameter processing:
while getopts "ae:fhk:mnvR:" Option
do
  case $Option in
    h ) echo "Generate GPG signatures (.asc files) of our tarballs."
        echo "By default, do not touch any existing signature files."
        echo "Usage:"
        echo "  $0 [OPTION] ..."
        echo ""
        echo "The REPOSROOT is the directory that contains your packages."
        echo "Current value of REPOSROOT : $REPOSROOT"
        echo ""
        echo "Parameters are:"
        echo "  -a     : Re-create _all_ package .asc gpg signature files -"
        echo "           The default is to only create missing .asc files."
        echo "  -e ext : Specify a different package extension than '$FEXT'."
        echo "  -f     : Fix .asc signature files that don't verify correctly."
        echo "           This check is done additionally to the generation"
        echo "           of any absent .asc files."
        echo "  -h     : This help text."
        echo "  -k key : Use this gpg key instead of '$REPOSKEY'."
        echo "  -n     : Dry-run: show what would be done but don't write."
        echo "  -v     : Verbose output."
        echo "  -R dir : Use 'dir' as the REPOSROOT."
        exit
        ;;
    a ) FORCEASC="yes"
        ;;
    e ) FEXT=${OPTARG}
        ;;
    f ) CHECKASC="yes"
        ;;
    k ) REPOSKEY=${OPTARG}
        ;;
    m ) ADDMD5="yes"
        ;;
    n ) DRYRUN="yes"
        ;;
    v ) DEBUG=1
        ;;
    R ) REPOSROOT="${OPTARG}"
        ;;
    * ) echo "You passed an illegal switch to the program!"
        echo "Run '$0 -h' for more help."
        exit
        ;;   # DEFAULT
  esac
done

# End of option parsing.
shift $(($OPTIND - 1))
#  $1 now references the first non option item supplied on the command line
#  if one exists.
# ---------------------------------------------------------------------------

#
# --- HELPER FUNCTIONS ------------------------------------------------------
#

#
# gpg_sign
#
function gpg_sign {
  # Create a gpg signature for a file. Use either gpg or gpg2 and optionally
  # let gpg-agent provide the passphrase.
  if [ $USE_GPGAGENT -eq 1 ]; then
    $GPGBIN -bas --batch --quiet $1
  else
    echo $TRASK | $GPGBIN -bas --passphrase-fd 0 --batch --quiet $1
  fi
  return $?
}

#
# genasc
#
function genasc {
  # Generate a package's GPG signature (*.asc file) if missing,
  # Argument #1 : full path to a package

  if [ ! -f "$1" ]; then
    echo "---> Required argument '$1' is invalid filename!"
    exit 1
  fi
  PKG=$1

  NAME=$(echo $PKG|sed -re "s/(.*\/)(.*.${FEXT})$/\2/")
  LOCATION=$(echo $PKG|sed -re "s/(.*)\/(.*.${FEXT})$/\1/")
  ASCFILE=${NAME}.asc

  if [ "$CHECKASC" == "yes" -a -f $LOCATION/$ASCFILE ]; then
    if ! GPGRESULT=$($GPGBIN --verify $LOCATION/$ASCFILE 2>&1); then
      if [ $DEBUG -eq 1 ]; then
        echo $GPGRESULT
        echo "*** Removing $LOCATION/$ASCFILE (not a valid signature) ***"
      fi
      if [ "$DRYRUN" == "no" ]; then
        rm -f $LOCATION/$ASCFILE
      fi
    fi
  fi

  if [ "$FORCEASC" == "yes" -o ! -f $LOCATION/$ASCFILE ]; then
    echo "---> Generating .asc file for $NAME"
    if [ "$DRYRUN" == "no" ]; then
      cd $LOCATION
      rm -f $ASCFILE
      gpg_sign $NAME
      cd - >/dev/null
      touch -r $PKG $LOCATION/$ASCFILE
    fi
  fi

} # end of function 'genasc'

#
# genmd5
#
function genmd5 {
  # Generate a package's MD5SUM (*.md5 file) if missing,
  # Argument #1 : full path to a package

  if [ ! -f "$1" ]; then
    echo "Required argument '$1' is not a valid file!"
    exit 1
  fi
  PKG=$1

  NAME=$(echo $PKG|sed -re "s/(.*\/)(.*.${FEXT})$/\2/")
  LOCATION=$(echo $PKG|sed -re "s/(.*)\/(.*.${FEXT})$/\1/")
  MD5FILE=${NAME}.md5

  if [ "$ADDMD5" == "yes" -a ! -f $LOCATION/$MD5FILE ]; then
    echo "--> Generating .md5 file for $NAME"
    (cd $LOCATION
     md5sum $NAME > $MD5FILE
    )
    touch -r $PKG $LOCATION/$MD5FILE
  fi

} # end of function 'genmd5'


#
# --- MAIN ------------------------------------------------------------------
#

# We will test correctness of the GPG passphrase against a temp file:
TESTTMP=$(mktemp)

# Retrieve the gpg key's owner name:
REPOSOWNER=${REPOSOWNER:-$($GPGBIN --list-keys |grep -w $REPOSKEY |tr -s ' ' |cut -f 4- -d' ')}

# Expand REPOSROOT to a full pathname:
REPOSROOT=$(cd $REPOSROOT ; pwd)

echo "--- Generating GPG signatures for files under directory:"
echo "---   '$REPOSROOT'"
echo "--- Repository owner is '$REPOSOWNER'"
echo "--- Using GPG key '$REPOSKEY' for signing"
echo ""
echo "--- Redefine the variable REPOSROOT if the packages to sign"
echo "--- are not located below '$REPOSROOT'"
echo ""
echo "--- Searching for package names that end on '$FEXT'"
echo "--- Run '$(basename $0) -h' if you want to see the commandline options."
echo ""

[ "$DEBUG" == "1" ] && echo "---> Enabling verbose output..."
[ "$DRYRUN" == "yes" ] && echo "---> Dry-run only..."

# Only generate GPG signatures if we have a GPG key
if ! $GPGBIN --list-secret-keys "$REPOSKEY" >/dev/null 2>&1
then
  USEGPG="no"
  echo "*** The required GPG private key: \"$REPOSKEY\""
  echo "*** for \"$REPOSOWNER\" wasn't found!"
  echo "*** Packages will not be signed!"
  read -er -p "Continue? [y|N] " 
  [ "${REPLY:0:1}" = "y" -o "${REPLY:0:1}" = "Y" ] || exit 1
else
  USEGPG="yes"
  if [ $USE_GPGAGENT -eq 0 ]; then
    read -ers -p "Enter your GPG passphrase: "
    TRASK=$REPLY
    echo "."
    if [ "$REPLY" == "" ]; then
      echo "Empty GPG passphrase - disabling generation of signatures."
      USEGPG="no"
    fi
  fi
fi

if [ "$USEGPG" == "yes" ]; then
  gpg_sign $TESTTMP 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "*** GPG test failed, incorrect GPG passphrase?"
    echo "*** Aborting the script."
    rm -f $TESTTMP
    exit 1
  elif ! [ "$DRYRUN" == "yes" -o -r ${REPOSROOT}/GPG-KEY ]; then
    echo "Generating a "GPG-KEY" file in '$REPOSROOT',"
    echo "   containing the public key information for '$REPOSOWNER'..."
    $GPGBIN --list-keys "$REPOSKEY" > ${REPOSROOT}/GPG-KEY
    $GPGBIN -a --export "$REPOSKEY" >> ${REPOSROOT}/GPG-KEY
    chmod 444 ${REPOSROOT}/GPG-KEY
  fi
fi

# Change directory to the root of the repository, so all generated
# information is relative to here:
cd $REPOSROOT

# Get a list of tarballs and generate the GPG signatures:
echo "---> Finding files in '$REPOSROOT', this can take a while..."
for pkg in $(find . -type f -name "*.${FEXT}" -print); do
  [ $DEBUG -eq 1 ] && echo "---> Found: $pkg"
  [ "$USEGPG" == "yes" ] && genasc $pkg
  [ "$ADDMD5" == "yes" ] && genmd5 $pkg
done

# Clean up:
TRASK=""


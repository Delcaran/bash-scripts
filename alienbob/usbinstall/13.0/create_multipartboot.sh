#!/bin/bash
# -----------------------------------------------------------------------------
# Purpose:
#   Create a multi-partition disk image (fat/ext2) to be used on a USB stick.
#   Afterwards, transfer the image to a USB stick as follows:
#     dd if=/tmp/slackboot/usbhd.img of=/dev/sdx
#   If your USB stick is not "/dev/sdx" use the correct device name!
#   The device's contents will be overwritten.
#   The resulting bootable USB stick can be used to install Slackware instead
#   of needing a CDROM.
#   What package series will fit on what size USB stick?
#   *  256 MB * a, ap, f, n   (the bare minimum)
#   *  512 MB * a, ap, n + d, f, l
#   * 1024 MB * a, ap, n + d, f, l + kde, tcl, x, xap, y
#   * 2048 MB * a, ap, n + d, f, l + kde, tcl, x, xap, y + e, k, kdei, t
#               plus extra and testing packages but excluding all sources
#   * 4096 MB * the whole Slackware tree incl. sources
# Credits:
#   Loosely using the instructions found at:
#   http://www.mega-tokyo.com/osfaq/Disk%20Images%20Under%20Linux
# Dependencies:
#   The 'ms-sys' program. This installs a working Master Boot Record (MBR).
#   Grab a package here: http://www.slackware.com/~alien/slackbuilds/ms-sys/
# Author:
#   Eric Hameleers <alien@slackware.com> 22-sep-2006
# Modified:
#   13-apr-2007 : Updated for new Slackware with only 2.6 kernels.
# Modified:
#   04-may-2008 : Updated for Slackware 12.1.
# Modified:
#   09-oct-2008 : Added '-s' option to create sparse file with 'dd'.
# Modified:
#   17-jul-2009 : Updated for Slackware 13.0 which comes in 64bit too (set the
#                 value of 'ARCH' to an appropriate value
#
# -----------------------------------------------------------------------------

cat <<"EOT"
# ------------------------------------------------------------------------#
# $Id: create_multipartboot.sh,v 1.32 2009/08/06 18:06:00 root Exp root $ #
# ------------------------------------------------------------------------#

EOT

IMGSIZE=253         # default disk image size in MB

IMGNAME=usbhd.img   # the output filename

# What architecture is this installer targeting?
ARCH=${ARCH:-"i486"}   # use "x86_64" for slackware64

# PKGMAIN: The name of the directory below which you find a,ap,d,...,y
# FATSIZE: Size in kb of the partition where the boot kernels and installer go
#          Do o't try to make this value less than '8100'
case $ARCH in
  x86_64) PKGMAIN=slackware64
          FATSIZE=15500
          ;;
  *)      PKGMAIN=slackware
          FATSIZE=23500
          ;;
esac

# Where are files created?
STAGING=${STAGING:-"/tmp/slackboot"}

# Where is our local Slackware mirror?
SLACKVERSION=${SLACKVERSION:-"13.0"}
SLACKROOT=${SLACKROOT:-"/home/ftp/pub/Linux/Slackware/slackware-${SLACKVERSION}"}

# File locations in the Slackware tree:
INITRDIMG="initrd.img"
INITRD="${SLACKROOT}/isolinux/${INITRDIMG}"

# The bootkernels not to include on the USB stick
# (for size considerations):
SKIPKERNELS="speakup.s"

# Various useful global variables:
CLEANUP="yes"
LOOPDEV=""
MSSYS="yes"
SPARSE="no"

CWD=$(pwd)
SRCDIR=$(cd $(dirname $0); pwd)

# -----------------------------------------------------------------------------

# The flip-over sizes in MB for the various USB formats - an advertized size
# of 1GB (which I read as 1024 MB) holds barely more than 1000 MB...:
IMGS_256=253
IMGS_512=505
IMGS_1024=1000
IMGS_2048=2000
IMGS_4096=4000

# The package series to include for the recognized USB sizes:
PKGS_256="a ap f n"
PKGS_512="a ap d f l n"
PKGS_1024="a ap d f kde l n tcl x xap y"
PKGS_2048="a ap d e f k kde kdei l n t tcl x xap y"
PKGS_4096="a ap d e f k kde kdei l n t tcl x xap y"

# Tweaking needed to fit as much as possible - leave out individual packages:
# Space separated:
EXCL_256=""
EXCL_512="d/gcc-java d/gcc-gnat"
EXCL_1024="d/gcc-java d/gcc-gnat kde/kdevelop kde/kdewebdev x/sazanami-fonts-ttf x/tibmachuni-font-ttf x/xorg-docs"
EXCL_2048=""
EXCL_4096=""

# Default extra rsync args
# (such as for adding additional directories, see below)
EXTRAARGS="--exclude bootdisks \
           --exclude extra \
           --exclude installer \
           --exclude isolinux \
           --exclude logs \
           --exclude pasture \
           --exclude patches \
           --exclude slackbook \
           --exclude source \
           --exclude testing \
           --exclude usb-and-pxe-installers \
           --exclude zipslack \
           --exclude ${PKGMAIN}/*"

# -----------------------------------------------------------------------------

cleanup() {
  # Clean up by unmounting our loopmounts, deleting tempfiles:
  echo "--- Cleaning up the staging area... ---"
  umount ${STAGING}/fat 2>/dev/null || true
  umount ${STAGING}/ext 2>/dev/null || true
  [ ! -z $LOOPDEV ] && losetup -d ${LOOPDEV} 2>/dev/null || true
  rm -rf ${STAGING}/newinitrd/*
  rm -rf ${STAGING}/work/*
  rm -f ${STAGING}/initrd.img*
}

# Do not tolerate sloppy scripting:
set -u
set -e
trap "echo \"*** $0 FAILED at line $LINENO ***\"; cleanup; exit 1" ERR INT TERM

while getopts "hcmns" Option ; do
case $Option in
  h ) echo "$0 -chmns <imgsize>"
      echo "Optional switches are:"
      echo "  -h   This help."
      echo "  -c   Don't generate any files, just cleanup tempfiles from a previous run,"
      echo "       and unmount any loopmounts that were left mounted."
      echo "  -m   Use syslinux MBR instead of requiring ms-sys package."
      echo "  -n   Generate files, but do not cleanup and leave images loopmounted."
      echo "       Use this if you want to inspect the content of the generated files."
      echo "  -s   Create a 'sparse' image file. This will save you time (the slow"
      echo "       process of filling the image with zeroes is omitted) but if you have"
      echo "       insufficient disk space you will only notice when copying packages."
      echo ""
      echo "The <imgsize> parameter is the size im MB of the generated disk image file."
      echo "Default value is 253 MB (for a 256 MB USB stick). Why the 3 MB less?"
      echo "I found out that my 256 MB stick had not enough room for a 256 MB image... "
      echo ""
      echo "----------------------------------------------------"
      echo "This is the list of package sets that will be added:"
      echo "  256MB stick - $PKGS_256"
      echo "  512MB stick - $PKGS_512"
      echo " 1024MB stick - $PKGS_1024"
      echo " 2048MB stick - $PKGS_2048"
      echo "----------------------------------------------------"
      echo ""
      echo "-------------------------------------------------"
      echo "This is the list of individual packages excluded:"
      echo "  256MB stick - $EXCL_256"
      echo "  512MB stick - $EXCL_512"
      echo " 1024MB stick - $EXCL_1024"
      echo " 2048MB stick - $EXCL_2048"
      echo "-------------------------------------------------"
      echo ""
      echo "++++++++++++++++++++++++++++++++++++++++"
      echo "Recommended values for disk image sizes:"
      echo "  256MB stick - create a $IMGS_256 MB image"
      echo "  512MB stick - create a $IMGS_512 MB image"
      echo " 1024MB stick - create a $IMGS_1024 MB image"
      echo " 2048MB stick - create a $IMGS_2048 MB image"
      echo " 4096MB stick - create a $IMGS_4096 MB image"
      echo "++++++++++++++++++++++++++++++++++++++++"
      echo ""
      exit
      ;;
  c ) cleanup
      exit
      ;;
  m ) MSSYS="no"
      ;;
  n ) CLEANUP="no"
      ;;
  s ) SPARSE="yes"
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

#
# -----------------------------------------------------------------------------
# Start of the real heavy lifting
# -----------------------------------------------------------------------------
#

# Sanity check:
if [ "$CWD" = "$STAGING" ]; then
  echo ""
  echo "*** Do not run this script in the output directory '$STAGING' !"
  echo ""
  exit 1
fi

# Was an image size specified on the commandline?
OPTION=${1:-${IMGSIZE}}

# Top off the OPTION value to what we actually require, so that the user can
# type "512" and we still create a 505 MB image:
if [ $OPTION -gt $IMGS_256 -a $OPTION -le 256 ] ; then
  OPTION=$IMGS_256
elif [ $OPTION -gt $IMGS_512 -a $OPTION -le 512 ] ; then
  OPTION=$IMGS_512
elif [ $OPTION -gt $IMGS_1024 -a $OPTION -le 1024 ] ; then
  OPTION=$IMGS_1024
elif [ $OPTION -gt $IMGS_2048 -a $OPTION -le 2048 ] ; then
  OPTION=$IMGS_2048
elif [ $OPTION -gt $IMGS_4096 -a $OPTION -le 4096 ] ; then
  OPTION=$IMGS_4096
fi

# Explain to the user what we are going to do:
if [ $OPTION -lt $IMGS_256 ] ; then
  echo "*** Sizes smaller than 253 MB are not accepted ***"
  exit 1
elif [ $OPTION -lt $IMGS_512 ] ; then
  echo "--- Creating $OPTION MB image for a 256 MB USB drive: ---"
  ADDPKGS=${PKGS_256}
  REMPKGS=${EXCL_256}
elif [ $OPTION -lt $IMGS_1024 ] ; then
  echo "--- Creating $OPTION MB image for a 512 MB USB drive: ---"
  ADDPKGS="${PKGS_512}"
  REMPKGS="${EXCL_512}"
elif [ $OPTION -lt $IMGS_2048 ] ; then
  echo "--- Creating $OPTION MB image for a 1024 MB USB drive: ---"
  ADDPKGS="${PKGS_1024}"
  REMPKGS="${EXCL_1024}"
elif [ $OPTION -lt $IMGS_4096 ] ; then
  echo "--- Creating $OPTION MB image for a 2048 MB USB drive: ---"
  ADDPKGS="${PKGS_2048}"
  REMPKGS="${EXCL_2048}"
  # Here we include /extra minus aspell-word-lists and source
  EXTRAARGS="--exclude bootdisks \
             --exclude extra/source \
             --exclude extra/aspell-word-lists \
             --include extra \
             --exclude isolinux \
             --exclude pasture \
             --exclude patches \
             --exclude source \
             --exclude testing \
             --exclude usb-and-pxe-installers \
             --exclude zipslack \
             --exclude ${PKGMAIN}/*"
else
  echo "--- Copying all of the Slackware tree to the USB image: ---"
  ADDPKGS=""
  REMPKGS=""
  EXTRAARGS=""
fi

# Compose the arguments to the rsync command used further down:
RSYNCARGS=""
for p in $ADDPKGS ; do
  RSYNCARGS="$RSYNCARGS --include ${PKGMAIN}/$p "
done
for p in $REMPKGS ; do
  RSYNCARGS="$RSYNCARGS --exclude ${PKGMAIN}/$p* "
done
for p in $SKIPKERNELS ; do
  RSYNCARGS="$RSYNCARGS --exclude kernels/$p "
done

# Cleanup any leftover tempfiles and mounts from a previous run:
cleanup

# Delete any existing output files from a previous run:
rm -f ${STAGING}/${IMGNAME}*

if [ ! -d $SLACKROOT ]; then
  echo "*** I can't find the Slackware package tree $SLACKROOT!"
  exit 1
fi

# STAGING is where we will do all our work:
# loop-mounting the images, transfering data, writing the resulting images.
[ ! -d ${STAGING} ] && ( mkdir -p $STAGING || \
  ( echo "*** Could not create directory ${STAGING}!"; exit 1 ) )

if [ "x$MSSYS" != "xno"  ]; then
  if ! `which ms-sys > /dev/null 2>&1`; then
    echo "*** The 'ms-sys' program is missing! ***"
    echo "Package can be found at http://www.slackware.com/~alien/slackbuilds/ms-sys/"
    exit 1
  fi
fi

# Mount points, place to build the new initrd:
mkdir ${STAGING}/{in,out,fat,ext,newinitrd,work} 2>/dev/null || true

# Create the empty file that we will use for our disk image.
# We will assume a disk geometry of #cylinders, 16 heads, 63 sectors/track,
# 512 bytes/sector, which means that each cylinder contains
# 516096 bytes (16*63*512).
(( NUMCYL=${OPTION}*1000*1024/516096 ))
echo "--- Creating $OPTION MB disk image: ---"
if [ "$SPARSE" = "no" ]; then
  dd if=/dev/zero of=${STAGING}/${IMGNAME} bs=516096c count=$NUMCYL
else
  dd if=/dev/zero of=${STAGING}/${IMGNAME} bs=516096c count=0 seek=$NUMCYL
fi

# Setup a loop device which lets us handle the image as a regular block device:
LOOPDEV=$( losetup -f )
losetup ${LOOPDEV} ${STAGING}/${IMGNAME}

# Partition the image file; use fdisk to create an MBR and partition table
# corresponding to our "hard disk geometry".
# We can safely ignore the "WARNING: Re-reading the partition table failed
# with error 22: Invalid argument":
echo "--- Ignore the 'WARNING: Re-reading the partition table failed'... ---"
(( FATCYLS=${FATSIZE}*1024/516096 ))
(( ENDFATCYL=${FATCYLS}+1 ))

# Actually, for the ext2 filesystem I use partition type 'da' - non-FS data
# so that the Slackware installer won't show the stick's partition as useable.
echo "--- Partitioning image with  FAT type 6 (FAT16) and Linux partitions: ---"
fdisk -C${NUMCYL} -S63 -H16 ${LOOPDEV} 1>${STAGING}/fdisk.log 2>&1 <<-EOF || true
	o
	n
	p
	1
	
	${ENDFATCYL}
	a
	1
	t
	6
	n
	p
	2
	
	
	t
	2
	da
	w
	EOF

# Show the contents:
fdisk -l -u -C${NUMCYL} -S63 -H16 ${LOOPDEV}

# Calculate start sector and the number of blocks used in the partitions
# (used later)
FATSTRT=$( fdisk -l -u -C${NUMCYL} -S63 -H16 ${LOOPDEV} | grep loop.p1 | tr -d '*' | tr -s ' ' | cut -f2 -d' ' )
FATBLKS=$( fdisk -l -u -C${NUMCYL} -S63 -H16 ${LOOPDEV} | grep loop.p1 | tr -d '*' | tr -s ' ' | cut -f4 -d' ' )
echo "*** FAT startsector: $FATSTRT - numblocks: ${FATBLKS%+} ***"
EXTSTRT=$( fdisk -l -u -C${NUMCYL} -S63 -H16 ${LOOPDEV} | grep loop.p2 | tr -d '*' | tr -s ' ' | cut -f2 -d' ' )
EXTBLKS=$( fdisk -l -u -C${NUMCYL} -S63 -H16 ${LOOPDEV} | grep loop.p2 | tr -d '*' | tr -s ' ' | cut -f4 -d' ' )
echo "*** ext2 startsector: $EXTSTRT - numblocks: ${EXTBLKS%+} ***"

# Add a standard bootsector to the image (if you have not installed ms-sys you
# might try to install the file 'mbr.bin' from the syslinux package in the MBR
# - NOTE - the file 'mbr.bin' is *not* included in the Slackware package!):
# I had mixed results with that mbr.bin file - the ms-sys package creates a
# cleaner boot record.
if [ "x$MSSYS" == "xno"  ]; then
  dd if=${SRCDIR}/mbr.bin of=${LOOPDEV}
else
  ms-sys -sf ${LOOPDEV}
fi

# Unmount the loop device
losetup -d ${LOOPDEV}

# ... and remount it, offset so that we can format the first (FAT) partition
# which starts at sector 63 (63*512=32256 bytes)
(( FATSTRT=${FATSTRT}*512 ))
LOOPDEV=$( losetup -f )
losetup -o${FATSTRT} ${LOOPDEV} ${STAGING}/${IMGNAME}
# Format as FAT16 (that is the only FAT type syslinux can cope with)
# and get rid of a potential '+'.
mkdosfs -n USBSLACK -F16 ${LOOPDEV} ${FATBLKS%+}
# Unmount the loop device
losetup -d ${LOOPDEV}

# Now the ext2 partition:
(( EXTSTRT=${EXTSTRT}*512 ))
LOOPDEV=$( losetup -f )
losetup -o${EXTSTRT} ${LOOPDEV} ${STAGING}/${IMGNAME}
# Get rid of a potential '+'.
mke2fs -q -b1024 -m 0 ${LOOPDEV} ${EXTBLKS%+}
tune2fs -L USBSLACKINSTALL -i 0 ${LOOPDEV}
# Unmount the loop device
losetup -d ${LOOPDEV}

#
# --- Patch the initrd.img for USB install ---
#

# Check if we have a newer/custom initrd:
if [ -f $CWD/$INITRDIMG ]; then
  echo "!!! Using an existing custom initrd '$CWD/$INITRDIMG': !!!"
  INITRD="$CWD/$INITRDIMG"
elif [ -f $SRCDIR/$INITRDIMG ]; then
  echo "!!! Using an existing custom initrd '$SRCDIR/$INITRDIMG': !!!"
  INITRD="$SRCDIR/$INITRDIMG"
fi

# Expand the gzipped root fs:
( cd ${STAGING}/newinitrd
  echo "  >>> Extracting Slackware initrd.img "
  gunzip -cd ${INITRD} | cpio -i -d -H newc --no-absolute-filenames
)

# Copying/patching usb, media and kernel scripts to newinitrd tree:
echo "  --- Patching the Slackware 'initrd.img' for use with USB: ---"
( cd ${STAGING}/newinitrd && ln -s /var/log/mount disk )
cp -a $SRCDIR/INSUSB ${STAGING}/newinitrd/usr/lib/setup/
chmod +x ${STAGING}/newinitrd/usr/lib/setup/INSUSB
patch -p0 ${STAGING}/newinitrd/usr/lib/setup/SeTmedia $SRCDIR/SeTmedia.diff
patch -p0 ${STAGING}/newinitrd/etc/rc.d/rc.usb $SRCDIR/rc.usb.diff

# Morph the newinitrd tree into a initramfs:
echo "  --- Gzipping the resulting initrd image (initramfs format): ---"
( cd ${STAGING}/newinitrd
  find . | cpio -o -H newc | gzip > ${STAGING}/initrd.img
)
(cd ${STAGING} && md5sum initrd.img > initrd.img.md5)

#
# --- Copy data into the usbhd.img ---
#

# Populate the FAT partition:
mount -t vfat -o rw,loop,offset=${FATSTRT} ${STAGING}/${IMGNAME} ${STAGING}/fat

echo "--- Copying installer files to the image file's FAT partition: ---"
echo "--- Available space: $( df -H ${STAGING}/fat | grep ${STAGING}/fat | tr -s ' ' |cut -f4 -d' ' ) ---"
cp ${STAGING}/initrd.img ${STAGING}/fat/
cp $SLACKROOT/isolinux/setpkg ${STAGING}/fat/
cp $SLACKROOT/isolinux/{f2,message}.txt ${STAGING}/fat/

cat ${SLACKROOT}/isolinux/isolinux.cfg | sed -e 's# /kernels/# #g' -e 's#/.zImage##' -e 's#\(SLACK_KERNEL=[a-z.0-9]*\)#\1 PKGSRC=USB#'  > ${STAGING}/fat/syslinux.cfg

# (Older) syslinux can not cope with subdirectories:
(
  cd $SLACKROOT/kernels/
  # Leave out kernels we don't need or want (to save on disk space)
  # SKIPKERNELS should not be empty or the 'grep' messes things up:
  if [ -n "$SKIPKERNELS" ]; then
    echo "--- Kernels not copied to the USB image: '$SKIPKERNELS' ---"
  fi
  SKIPKERNELS=${SKIPKERNELS:-xxxxxxxx}
  for dir in `find  -type d -name "*.?" -maxdepth 1 | grep -vE "(${SKIPKERNELS// /|/})"` ; do
    cp $dir/*zImage ${STAGING}/fat/$dir
  done
)
sync
echo "--- FAT partition: $( df -H ${STAGING}/fat | grep ${STAGING}/fat | tr -s ' ' |cut -f4 -d' ' ) free space left ---"
umount ${STAGING}/fat

# Stamp the file with the syslinux bootloader:
#   > Do "vi ~/.mtoolsrc" to add "mtools_skip_check=1",
#   > if the next command gives an error:
echo "--- Making the image bootable: ---"
LOOPDEV=$( losetup -f )
losetup -o${FATSTRT} ${LOOPDEV} ${STAGING}/${IMGNAME}
syslinux -s ${LOOPDEV}
losetup -d ${LOOPDEV}

# Now the ext2 partition:
mount -t ext2 -o loop,offset=${EXTSTRT} ${STAGING}/${IMGNAME} ${STAGING}/ext
echo "--- Copying packages to the image file's ext2 partition: ---"
echo "--- Available space: $( df -H ${STAGING}/ext | grep ${STAGING}/ext | tr -s ' ' |cut -f4 -d' ' ) ---"

# Leave a descriptive message inside the installer:
cat <<EOTT > ${STAGING}/ext/USB_INSTALLER_CONTENT.TXT
This is Alien's USB Slackware installer.

This USB image was created on $(date +%Y%m%d\ %H:%M) ;
It contains Slackware for $ARCH version $SLACKVERSION

--- The following package series were copied to the $OPTION MB USB image: ---
    '${ADDPKGS:-all}'
--- ... of which the following individual packages were omitted: ---
    '${REMPKGS:-none}'

See also http://www.slackware.com/~alien/tools/usbinstall/

====================================================================
Eric Hameleers <alien@slackware.com>
EOTT

rsync -rlptD \
  $RSYNCARGS \
  $EXTRAARGS \
  ${SLACKROOT}/* ${STAGING}/ext/
sync
echo "--- ext2 partition: $( df -H ${STAGING}/ext | grep ${STAGING}/ext | tr -s ' ' |cut -f4 -d' ' ) free space left ---"
umount ${STAGING}/ext

# Finished copying data. Let's wrap up.

(cd  ${STAGING} && md5sum ${IMGNAME} > ${IMGNAME}.md5)

(
if [ $OPTION -le $IMGS_256 ] ; then
  echo "--- Only copied Slackware package series that would fit on 256 MB sticks ---"
  echo "--- You could try adding more yourself afterwards ---"
elif [ $OPTION -le $IMGS_512 ] ; then
  echo "--- Only copied Slackware package series that would fit on 512 MB sticks ---"
  echo "--- You could try adding more yourself afterwards ---"
elif [ $OPTION -le $IMGS_1024 ] ; then
  echo "--- Only copied Slackware package series that would fit on 1024 MB sticks ---"
  echo "--- You could try adding more yourself afterwards ---"
elif [ $OPTION -le $IMGS_2048 ] ; then
  echo "--- All core Slackware packages copied, plus those from extra and testing ---"
  echo "--- There probably is room for more packages, check it out yourself ---"
else
  echo "--- Complete Slackware tree copied ---"
  echo "--- There probably is room for more stuff, check it out yourself ---"
fi
echo ""
echo "--- Ext2 partition mount command: ---"
echo "    mount -t ext2 -o loop,offset=${EXTSTRT} ${STAGING}/${IMGNAME} ${STAGING}/ext"

echo "--- The following package series were copied to the USB image: ---"
echo "    '${ADDPKGS:-all}'"
echo "--- ... of which the following individual packages were omitted: ---"
echo "    '${REMPKGS:-none}'"
#echo ">>> RSYNCARGS: $RSYNCARGS <<<"
) | tee ${STAGING}/${IMGNAME}.txt

echo ""
echo "------------------------------------------------------------------------"
echo "The new image file (for USB boot and install) is:"
echo "    '${STAGING}/${IMGNAME}'"
echo "------------------------------------------------------------------------"
echo ""

# Cleanup any left-overs:
if [ "$CLEANUP" == "no" ] ; then
  # Re-mount images for forensic inspection:
  mount -t vfat -o loop,offset=${FATSTRT} ${STAGING}/${IMGNAME} ${STAGING}/fat
  mount -t ext2 -o loop,offset=${EXTSTRT} ${STAGING}/${IMGNAME} ${STAGING}/ext
else
  cleanup
fi


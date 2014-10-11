#!/bin/sh
# $Id: create_multipartboot.sh,v 1.8 2006/10/03 20:23:12 root Exp root $
# -----------------------------------------------------------------------------
# Purpose:
#   Create a multi-partition disk image (fat/ext2) to be used on a USB stick.
#   Afterwards, transfer the image to a USB stick as follows:
#     dd if=/tmp/slackboot/usbhd.img of=/dev/sda
#   If your USB stick is not "/dev/sda" use the correct device name!
#   The device's contents will be overwritten.
#   The resulting bootable USB stick can be used to install Slackware instead
#   of needing a CDROM.
#   What package series will fit on what size USB stick?
#   *  256 MB * a, ap, n   (the bare minimum)
#   *  512 MB * a, ap, n plus d, k, l
#   * 1024 MB * a, ap, n plus d, k, l plus f, kde, tcl, x, xap, y
#   * 2048 MB * a, ap, n plus d, k, l plus f, kde, tcl, x, xap, y plus e, kdei, t
# Credits:
#   Loosely using the instructions found at:
#   http://www.mega-tokyo.com/osfaq/Disk%20Images%20Under%20Linux
# Dependencies:
#   The 'ms-sys' program. This installs a working Master Boot Record (MBR).
#   Grab a package here: http://www.slackware.com/~alien/slackbuilds/ms-sys/
# Author:
#   Eric Hameleers <alien@slackware.com> 22-sep-2006
#
# -----------------------------------------------------------------------------
#

IMGSIZE=253         # default disk image size in MB
FATSIZE=23500       # size of the FAT partition in kB

IMGNAME=usbhd.img   # the output filename

# Where are files created?
STAGING=${STAGING:-/tmp/slackboot}

# Where is our local Slackware mirror?
SLACKROOT=${SLACKROOT:-/home/ftp/pub/Linux/Slackware/slackware-current}

# -----------------------------------------------------------------------------

INITRD="${SLACKROOT}/isolinux/initrd.img"
DEFKERNEL="sata.i"
SYSMAP="${SLACKROOT}/kernels/${DEFKERNEL}/System.map.gz"
SYSMAP26="${SLACKROOT}/kernels/huge26.s/System.map.gz"

# The bootkernels not to include on the USB stick
# (PC's needing these kernels probably will not allow USB booting anyway)
SKIPKERNELS="ibmmca.s old_cd.i pportide.i test26.s zipslack.s"

# The package series to include for the recognized USB sizes:
PKGS_256="a ap n"
PKGS_512="a ap d f k l n tcl y"
PKGS_1024="a ap d f k kde l n tcl x xap y"
PKGS_2048="a ap d e f k kde kdei l n t tcl x xap y"

# Tweaking needed to fit as much as possible - leave out individual packages:
EXCL_256=""
EXCL_512="l/jre"
EXCL_1024=""
EXCL_2048=""

# Extra rsync args (such as for adding additional directories, see below)
EXTRAARGS="--exclude bootdisks \
           --exclude extra \
           --exclude isolinux \
           --exclude pasture \
           --exclude patches \
           --exclude rootdisks \
           --exclude source \
           --exclude testing \
           --exclude zipslack \
           --exclude slackware/*"

# -----------------------------------------------------------------------------

LOOPDEV=""
CWD=$( pwd )
SRCDIR=$( dirname $0 )
[ "${SRCDIR:0:1}" == "." ] && SRCDIR=${CWD}/${SRCDIR}

cleanup() {
  # Clean up by unmounting our loopmounts, deleting tempfiles:
  echo "--- Cleaning up the staging area... ---"
  umount ${STAGING}/in 2>/dev/null || true
  umount ${STAGING}/out 2>/dev/null || true
  umount ${STAGING}/fat 2>/dev/null || true
  umount ${STAGING}/ext 2>/dev/null || true
  [ ! -z $LOOPDEV ] && losetup -d ${LOOPDEV} 2>/dev/null || true
  rm -f ${STAGING}/newinitrd
  rm -f ${STAGING}/initrd.dsk
  rm -f ${STAGING}/System*.map
}

# Do not tolerate sloppy scripting:
set -u
set -e
trap "echo \"*** $0 FAILED ***\"; cleanup; exit 1" ERR INT TERM

CLEANUP="yes"
while getopts "hcn" Option
do
  case $Option in
    h ) echo "$0 -hnc <imgsize>"
        echo "Optional switches are:"
        echo "  -h     This help."
        echo "  -c     Don't generate files - cleanup tempfiles from a previous run,"
        echo "         and unmount any loopmounts that were left mounted."
        echo "  -n     Generate files, but do not cleanup and leave images loopmounted."
        echo "         Use this if you want to inspect the content of the generated files."
        echo ""
        echo "The <imgsize> parameter is the size im MB of the generated disk image file."
        echo "Default value is 253 MB (for a 256 MB USB stick). Why the 3 MB less?"
        echo "I found out that my 256 MB stick had not enough room for a 256 MB image... "
        echo ""
        exit
        ;;
    c ) cleanup
        exit
        ;;
    n ) CLEANUP="no"
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
#

# Was an image size specified on the commandline?
OPTION=${1:-${IMGSIZE}}

if [ $OPTION -lt 253 ] ; then
  echo "*** Sizes smaller than 253 MB are not accepted ***"
  exit 1
elif [ $OPTION -lt 509 ] ; then
  ADDPKGS=${PKGS_256}
  REMPKGS=${EXCL_256}
elif [ $OPTION -lt 1020 ] ; then
  ADDPKGS="${PKGS_512}"
  REMPKGS="${EXCL_512}"
elif [ $OPTION -lt 2000 ] ; then
  ADDPKGS="${PKGS_1024}"
  REMPKGS="${EXCL_1024}"
else
  ADDPKGS="${PKGS_2048}"
  REMPKGS="${EXCL_2048}"
  EXTRAARGS="--exclude bootdisks \
             --exclude extra/source \
             --include extra \
             --exclude isolinux \
             --exclude pasture \
             --exclude patches \
             --exclude rootdisks \
             --exclude source \
             --include testing/packages \
             --exclude testing/* \
             --exclude zipslack \
             --exclude slackware/*"
fi

# Compose the arguments to the rsync command used further down:
RSYNCARGS=""
for p in $ADDPKGS ; do
  RSYNCARGS="$RSYNCARGS --include slackware/$p "
done
for p in $REMPKGS ; do
  RSYNCARGS="$RSYNCARGS --exclude slackware/$p* "
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

if [ ! -x `which ms-sys` ] ; then
  echo "ms-sys program is missing!"
  echo "Package can be found at http://www.slackware.com/~alien/slackbuilds/ms-sys/"
  exit 1
fi

# Mount points:
mkdir ${STAGING}/{in,out,fat,ext} 2>/dev/null || true

# Create the empty file that we will use for our disk image.
# We will assume a disk geometry of #cylinders, 16 heads, 63 sectors/track,
# 512 bytes/sector, which means that each cylinder contains
# 516096 bytes (16*63*512).
let NUMCYL=${OPTION}*1000*1024/516096
echo "--- Creating $OPTION MB disk image: ---"
dd if=/dev/zero of=${STAGING}/${IMGNAME} bs=516096c count=$NUMCYL

# Setup a loop device which lets us handle the image as a regular block device:
LOOPDEV=$( losetup -f )
losetup ${LOOPDEV} ${STAGING}/${IMGNAME}

# Partition the image file; use fdisk to create an MBR and partition table
# corresponding to our "hard disk geometry".
# We can safely ignore the "WARNING: Re-reading the partition table failed
# with error 22: Invalid argument":
let FATCYLS=${FATSIZE}*1024/516096

# Actually, for the ext2 filesystem I use partition type 'da' - non-FS data
# so that the Slackware installer won't show the stick's partition as useable.
echo "--- Partitioning image with  FAT and Linux partitions: ---"
fdisk -C${NUMCYL} -S63 -H16 ${LOOPDEV} <<-EOF || true
	o
	n
	p
	1
	
	+${FATCYLS}
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
#dd if=${SRCDIR}/mbr.bin of=${LOOPDEV}
ms-sys -sf ${LOOPDEV}

# Unmount the loop device
losetup -d ${LOOPDEV}

# ... and remount it, offset so that we can format the first (FAT) partition
# which starts at sector 63 (63*512=32256 bytes)
let FATSTRT=${FATSTRT}*512
LOOPDEV=$( losetup -f )
losetup -o${FATSTRT} ${LOOPDEV} ${STAGING}/${IMGNAME}
# Format as FAT16 (that is the only FAT type syslinux can cope with)
# and get rid of a potential '+'.
mkdosfs -n USBSLACK -F16 ${LOOPDEV} ${FATBLKS%+}
# Unmount the loop device
losetup -d ${LOOPDEV}

# Now the ext2 partition:
let EXTSTRT=${EXTSTRT}*512
LOOPDEV=$( losetup -f )
losetup -o${EXTSTRT} ${LOOPDEV} ${STAGING}/${IMGNAME}
# Get rid of a potential '+'.
mke2fs -b1024 -m 0 ${LOOPDEV} ${EXTBLKS%+}
tune2fs -L USBSLACKINSTALL -i 0 ${LOOPDEV}
# Unmount the loop device
losetup -d ${LOOPDEV}

#
# --- Patch the initrd.img for USB install ---
#

# Expand the gzipped root fs:
gunzip -cd ${INITRD} > ${STAGING}/initrd.dsk

# Calculate minimum size of ramdisk:
RDSIZE=$( du -sk ${STAGING}/initrd.dsk | cut -f1 )
# Allow for a little more so we can squeeze in extra modules if needed:
let RDSIZE=$RDSIZE+150

# Create new image file big enough to contain the resulting initrd:
echo "  --- Patching the Slackware 'initrd.img' for use with USB: ---"
dd if=/dev/zero of=${STAGING}/newinitrd bs=1k count=${RDSIZE}

# Create an ext2 filesystem in it:
mkfs.ext2 -m 0 -F ${STAGING}/newinitrd
tune2fs -i 0 ${STAGING}/newinitrd

# Mount images and start copying data:
mount -o loop ${STAGING}/newinitrd ${STAGING}/out/
mount -o loop,ro ${STAGING}/initrd.dsk ${STAGING}/in/

# Copy data to loop-mounted newinitrd file:
cp -a ${STAGING}/in/* ${STAGING}/out/

# Copying/patching usb, media and kernel scripts:
( cd ${STAGING}/out && ln -s /var/log/mount disk)
cp -a $SRCDIR/INSUSB ${STAGING}/out/usr/lib/setup/
patch -p0 ${STAGING}/out/usr/lib/setup/SeTmedia $SRCDIR/SeTmedia.diff
patch -p0 ${STAGING}/out/usr/lib/setup/SeTkernel $SRCDIR/SeTkernel.diff
patch -p0 ${STAGING}/out/etc/rc.d/rc.usb $SRCDIR/rc.usb.diff
patch -p0 ${STAGING}/out/bin/network $SRCDIR/network.diff
patch -p0 ${STAGING}/out/bin/pcmcia $SRCDIR/pcmcia.diff

echo "  --- INITRD: $( df -H ${STAGING}/out | grep ${STAGING}/out | tr -s ' ' |cut -f4 -d' ' ) free space left ---"

# Gzip the new initrd:
umount ${STAGING}/out
echo "  --- Gzipping the resulting initrd image: ---"
gzip -9cf ${STAGING}/newinitrd > ${STAGING}/initrd.img
umount ${STAGING}/in

#
# --- Copy data into the usbhd.img ---
#

# Populate the FAT partition:
mount -t vfat -o rw,loop,offset=${FATSTRT} ${STAGING}/${IMGNAME} ${STAGING}/fat

echo "--- Copying installer to the image file's FAT partition: ---"
cp ${STAGING}/initrd.img ${STAGING}/fat/
cp $SLACKROOT/isolinux/setpkg ${STAGING}/fat/
cp $SLACKROOT/isolinux/{f2.txt,message.txt} ${STAGING}/fat/
cat $SLACKROOT/isolinux/f3.txt | grep -vE "(${SKIPKERNELS// /|/})" > ${STAGING}/fat/f3.txt

cat ${SLACKROOT}/isolinux/isolinux.cfg | sed -e "s/ramdisk_size=[[:digit:]]*/ramdisk_size=${RDSIZE}/" | sed -e 's# /kernels/# #g' -e 's#/.zImage##' -e 's#\(SLACK_KERNEL=[a-z.0-9]*\)#\1 PKGSRC=USB#'  > ${STAGING}/fat/syslinux.cfg

# Syslinux can not cope with subdirectories:
(
  cd $SLACKROOT/kernels/
  # Leave out kernels we don't need or want (to save on disk space)
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
rsync -rlptD \
  $RSYNCARGS \
  $EXTRAARGS \
  ${SLACKROOT}/* ${STAGING}/ext/
mkdir -p ${STAGING}/ext/rootdisks/
cp $SLACKROOT/isolinux/{network*,pcmcia}.dsk ${STAGING}/ext/rootdisks/
sync
echo "--- ext2 partition: $( df -H ${STAGING}/ext | grep ${STAGING}/ext | tr -s ' ' |cut -f4 -d' ' ) free space left ---"
umount ${STAGING}/ext

# Finished copying data. Let's wrap up.

(cd  ${STAGING} && md5sum ${IMGNAME} > ${IMGNAME}.md5)

if [ $OPTION -lt 509 ] ; then
  echo "--- Only copied Slackware package series that would fit on 256 MB sticks ---"
  echo "--- You could try adding more yourself afterwards ---"
elif [ $OPTION -lt 1020 ] ; then
  echo "--- Only copied Slackware package series that would fit on 512 MB sticks ---"
  echo "--- You could try adding more yourself afterwards ---"
else
  echo "--- There probably is room for more packages, check it out yourself ---"
fi
echo "--- Ext2 partition mount command: ---"
echo "    mount -t ext2 -o loop,offset=${EXTSTRT} ${STAGING}/${IMGNAME} ${STAGING}/ext"

echo "--- The following package series were copied to the USB image: ---"
echo "    $ADDPKGS"
#echo ">>> RSYNCARGS: $RSYNCARGS <<<"


echo ""
echo "------------------------------------------------------------------------"
echo "The new image file (for USB boot and install) is:"
echo "    '${STAGING}/${IMGNAME}'"
echo "------------------------------------------------------------------------"
echo ""

# Cleanup any left-overs:
if [ "$CLEANUP" == "no" ] ; then
  # Re-mount images for forensic inspection:
  mount -o loop ${STAGING}/newinitrd ${STAGING}/out/
  mount -t vfat -o loop,offset=${FATSTRT} ${STAGING}/${IMGNAME} ${STAGING}/fat
  mount -t ext2 -o loop,offset=${EXTSTRT} ${STAGING}/${IMGNAME} ${STAGING}/ext
else
  cleanup
fi


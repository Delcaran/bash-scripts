#!/bin/sh
#
# Start Slackware in QEMU
#
## ---------------------------------------------------------------------------
## Create a 5GB image file like this:
## # dd if=/dev/zero of=slackware.img bs=1k count=5000000
##
## Create the QCOW (qemu copy-on-write) file like this:
## # qemu-img create -b slackware.img -f qcow slackware.qcow
##
## Commit changes made in the QCOW file back to the base image like this:
## # qemu-img commit slackware.qcow
##
## After the commit, you can delete and re-create a new QCOW file.
## ---------------------------------------------------------------------------

# Location of your QEMU images:
IMAGEDIR=/QEMU/images

#[ ! -z $* ]  && PARAMS=$*
PARAMS=$*

# Qemu can use SDL sound instead of the default OSS
export QEMU_AUDIO_DRV=sdl

# Whereas SDL can play through alsa:
export SDL_AUDIODRIVER=alsa

cd $IMAGEDIR
# Use this command line only for the initial network install of Slackware
# (in this example slackware-current):
#qemu -m 256 -localtime -kernel-kqemu -usb -hda slackware.img -cdrom ./slackware-current-install-dvd.iso -boot d  1>slackware.log 2>slackware.err ${PARAMS} &
# This is the command line for real work.
# Add/delete/modify qemu parameters as you see fit:
qemu -m 256 -localtime -soundhw all -kernel-kqemu -usb \
  -hda slackware.qcow \
  -cdrom ./slackware-current-install-dvd.iso \
  1>slackware.log 2>slackware.err ${PARAMS} &


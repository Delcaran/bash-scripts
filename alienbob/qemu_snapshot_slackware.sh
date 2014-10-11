#!/bin/sh
#
# Start Slackware in QEMU
# Use QEMU snapshots for the purpose of testing software in a clean environment.

## ---------------------------------------------------------------------------
## Create a 5GB image file like this:
## # dd if=/dev/zero of=slackware.img bs=1k count=5000000
##
## Create the QCOW (qemu copy-on-write) file like this:
## $ qemu-img create -b slackware.img -f qcow slackware_snapshot.qcow
##
## DO NOT commit the changes made in the QCOW file back to the base image!
## The QCOW image is only used once and re-created every time the script runs!
## ---------------------------------------------------------------------------

# Location of your QEMU images:
IMAGEDIR=~/QEMU/images

#[ ! -z $* ]  && PARAMS=$*
PARAMS=$*

# Qemu can use SDL sound instead of the default OSS
export QEMU_AUDIO_DRV=sdl

# Whereas SDL can play through alsa:
export SDL_AUDIODRIVER=alsa

cd $IMAGEDIR
# Remove old QCOW file, create a new one:
rm -f slackware_snapshot.qcow
qemu-img create -b slackware.img -f qcow slackware_snapshot.qcow
# Start QEMU with the fresh image:
qemu -m 256 -localtime -usb -soundhw all -kernel-kqemu \
        -hda slackware_snapshot.qcow ${PARAMS} \
        >slackware_snapshot.log 2>slackware_snapshot.err &


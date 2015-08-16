#!/bin/bash

ISO=$1
DEVICE=/dev/cdrom
SPEED=2.4

md5=$(md5sum ${ISO})
blocks=$(expr $(ls -l ${ISO} | awk '{print $5}') / 2048)

growisofs -dvd-compat -speed=${SPEED} -Z ${DEVICE}=${ISO}




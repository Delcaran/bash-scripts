#!/bin/bash

source "/home/delcaran/scripts/config.sh"
MOUNTPOINT=""
SRCDIR=""

case $1 in
    secureext)
        SRCDIR="${SECURE_EXT_ENCFS}"
        MOUNTPOINT="${MOUNT_SECURE_EXT}"
        ;;
    secureint)
        SRCDIR="${SECURE_INT_ENCFS}"
        MOUNTPOINT="${MOUNT_SECURE_INT}"
        ;;
    skydrive)
        SRCDIR="${FFOLDER_ENCFS}"
        MOUNTPOINT="${ENCFS_FFOLDER}"
        ;;
#    4chan)
#        SRCDIR="${4CHAN_ENCFS}"
#        MOUNTPOINT="${MOUNT_4CHAN}"
#        ;;
    *)
        echo "Cartella sconosciuta. Cartelle disponibili:"
        echo "\tsecureext"
        echo "\tsecureint"
        echo "\tffolder"
#        echo "\t4chan"
        exit 1
        ;;
esac

encfs -f "${SRCDIR}" "${MOUNTPOINT}" # -- "${ENCFS_OPTIONS}"

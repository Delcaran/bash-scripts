#!/bin/bash

source "/home/delcaran/scripts/config.sh"

if [ ! -f "${FONERA_DIR}/${FONERA_OVPN}" ]
then
#	bash "${SCRIPT_TRUECRYPT_MOUNT}"
	bash "${SCRIPT_ENCFS_MOUNT}"
fi
sleep 5
sudo cd "${FONERA_DIR}"
sudo openvpn "${FONERA_OVPN}"
exit 0

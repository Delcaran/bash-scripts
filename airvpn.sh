#!/bin/bash

sudo openvpn --config /etc/openvpn/airvpn.ovpn
exit 0

source "/home/delcaran/scripts/config.sh"

if [ ! -f "${AIRVPN_DIR}/${AIRVPN_OVPN}" ]
then
	bash "${SCRIPT_ENCFS_MOUNT} secureext"
fi
sleep 5
cd "${AIRVPN_DIR}"
sudo openvpn "${AIRVPN_OVPN}"
exit 0

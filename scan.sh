#!/bin/bash
DEVICE=$1
OUTPUT_NAME=$2
OUTPUT_NUMBER=$3
#RESOLUTION="300dpi"
RESOLUTION="600dpi"

scanimage -d ${DEVICE} --mode Gray --resolution ${RESOLUTION} > "${OUTPUT_NAME}_${OUTPUT_NUMBER}.pnm"
#    --mode Linear \
#    --mode Gray \
#    --mode Color \
#   --resolution ${RESOLUTION} \
#   > \
#    "${OUTPUT_NAME}_${OUTPUT_NUMBER}.pnm"

convert "${OUTPUT_NAME}_${OUTPUT_NUMBER}.pnm" \
    "${OUTPUT_NAME}_${OUTPUT_NUMBER}.jpg"

rm "${OUTPUT_NAME}_${OUTPUT_NUMBER}.pnm"

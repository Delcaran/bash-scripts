#!/bin/bash
ENCODE=none
CHECK=1
OFFSET=6
CUE=none

#ENCODE=${1,,}
#CHECK=$2

#touch templog
#rip offset find | tee templog
#OFFSET=$(awk '/./{line=$0} END{print line}' templog | cut -d " " -f 6 | sed 's/[^0-9]//g')
#rm templog

if [ $OFFSET -ne 0 ] 
then
	rip cd rip -o $OFFSET
else
	rip cd rip
fi

CUE=$(find . -name *.cue -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

rip image retag "$CUE"

case $ENCODE in
	alac|mp3|flac|wav|wavpack|mp3vbr|vorbis)
		rip image encode --profile=${ENCODE} -O ${ENCODE} "$CUE"
		;;
esac

if [ $CHECK -ne 0 ] 
then
	rip image verify "$CUE"
fi

#!/bin/sh
DIR="/home/delcaran/Dropbox/Wallpapers/"
cd $DIR
while :
do
    feh --bg-scale "$(ls | sort -R | head -1)"
    sleep 15m
done
exit


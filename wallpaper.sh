#!/bin/sh
SERVICE='i3'
DIR="/home/delcaran/Pictures/Wallpapers/"
DISPLAY=:0
if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    DISPLAY=:0 feh --bg-scale "$(find $DIR|shuf -n1)"
fi
exit


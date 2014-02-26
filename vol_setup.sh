#!/bin/bash
LEVEL=2
COMMAND=""
PCMCOMMAND=""

case "$1" in
    "+") 
        COMMAND="${LEVEL}+"
        PCMCOMMAND="$COMMAND"
        ;;
    "-") 
        COMMAND="${LEVEL}-"
        PCMCOMMAND="$COMMAND"
        ;;
    "m") 
        if [ "`/usr/bin/amixer -c 0 sget 'PCM' | grep 100%`" ]
        then
            COMMAND="mute"
            PCMCOMMAND="0%"
        else
            COMMAND="unmute"
            PCMCOMMAND="100%"
        fi
        ;;
    *) exit 0 ;;
esac

/usr/bin/amixer -q set 'PCM' ${PCMCOMMAND}
/usr/bin/amixer -q set 'Master' ${COMMAND}
/usr/bin/amixer -q set 'Headphone' ${COMMAND}
/usr/bin/amixer -q set 'Speaker Front' ${COMMAND}
/usr/bin/amixer -q set 'Speaker Surround' ${COMMAND}
/usr/bin/amixer -q set 'Surround' ${COMMAND}
#/usr/bin/amixer -q set 'Speaker CLFE' ${COMMAND}
/usr/bin/amixer -q set 'Center' ${COMMAND}
/usr/bin/amixer -q set 'LFE' ${COMMAND}
#/usr/bin/amixer -q set 'Speaker' ${COMMAND}

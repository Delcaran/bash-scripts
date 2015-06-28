#! /bin/sh

# Simple autostart file for i3-wm, you can execute it from i3 config with
# exec $HOME/bin/auto-start-for-i3-simple
#
# xdotool and xmessage must be installed

# Wait for program
wait_for_program () {
    n=0
    while true
    do
	# PID of last background command
	if xdotool search --onlyvisible --pid $!; then
	    break
	else
	    # 20 seconds timeout
	    if [ $n -eq 20 ]; then
		#xmessage "Error on executing"
		break
	    else
		n=`expr $n + 1`
		sleep 1
	    fi
	fi
    done
}

# Start some programs
#
# ______________________
# |          |          |
# |  emacs   |  chrome  |
# |          |          |
# |          |          |
# |          |----------|
# |          |  xterm   |
# |__________|__________|


#emacs &
#wait_for_program

#i3-msg split h

#chromium &
#wait_for_program

#i3-msg split v

#xterm &
#wait_for_program

#terminator --name news -e newsbeuter &
#wait_for_program
#sleep 5

i3-msg split h
sleep 1

terminator --name mail -e "mutt -F /home/delcaran/.mutt/gmail" &
wait_for_program
sleep 5

i3-msg split v
sleep 1

terminator --name mail -e "mutt -F /home/delcaran/.mutt/spes" &
wait_for_program
sleep 5

i3-msg split h
sleep 1

exit 0

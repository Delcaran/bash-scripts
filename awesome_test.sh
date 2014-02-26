Xephyr -ac -br -noreset -screen 800x600 :2.0 &
sleep 1
DISPLAY=:2.0 awesome -c /home/delcaran/.config/awesome/rc.lua

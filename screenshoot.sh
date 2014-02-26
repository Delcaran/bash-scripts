cd /home/delcaran/Immagini/Screenshoots
num=`ls screenshoot* | wc -w`
new=$(($num+1))
import -window root screenshoot$new.png
cd
exit 0

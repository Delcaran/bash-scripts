CARTELLA="/home/delcaran/Dropbox/Wallpapers"
LISTA="/home/delcaran/.config/xfce4/desktop/backdrop.list"

find ${CARTELLA} -type f -regex ".*\.\(jpg\|gif\|png\|jpeg\)" > $LISTA

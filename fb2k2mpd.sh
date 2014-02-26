#!/bin/bash

SRC_DIR='/home/delcaran/Dropbox/Playlists'
DEST_DIR="${SRC_DIR}/mpd"

cd "${SRC_DIR}"

# copio playlist nella cartella
for pl in *.m3u
do
	cp -f "${SRC_DIR}/${pl}" "${DEST_DIR}/${pl}"
done

cd "${DEST_DIR}"

# cambio il formato del separatore delle directory
for pl in *.m3u
do
	sed -i 's/\\/\//g' "${pl}"
done

# sistemo il path delle playlist remote
for pl in AKIRA.m3u FLAC*.m3u
do
	sed -i 's/\/\/192.168.10.100\/raspberry\/hdd2\/torrent\/completi\/musica/raspberry/g' "${pl}"
done

# sistemo il path delle playlist locali
for pl in Best.m3u "Greatest Hits.m3u"
do
	sed -i 's/C:\/Users\/Delcaran\/Music\/Music/local/g' "${pl}"
done

mpc update

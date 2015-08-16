#!/bin/sh
dir=$1
if [[ $# < 1 ]] 
	then 
		echo "utilizzo: avi2ps3.sh <cartella_con_avi>"
		exit 1
fi
cd ${dir}
mkdir PS3
for file in *.avi
do
	filen="PS3/${file%%.avi}.mp4"
	fileo="${file}.done"
	HandBrakeCLI -Z normal -i ${file} -o ${filen}
	mv ${file} ${fileo}
done
cp *.mp4 PS3/
rename .mp4 .mp4.done *.mp4
cp *.m4v PS3/
rename .m4v .m4v.done *.m4v
exit 

play -n -c2 synth whitenoise band -n 100 20 band -n 50 20 gain +20 fade h 1 864000 1 &
play -n -c2 synth whitenoise lowpass -1 100 lowpass -1 50 gain +7 &
play -n -c2 synth whitenoise band -n 3900 50 gain -30 &
while : ; do
    oclock=$(date +"%H %M")
    espeak -p 0 -a 5 -v en-sc -s 50 "The Time is, $oclock "
    sleep 1
    espeak -p 300 -a 5 -v en-us -s 100 ",,, $oclock. Engage?"
    sleep 3
    espeak -p 10 -a 10 -v en-uk -s 150 " Yes,,,,  Engage,,,, Now!"
    sleep 300
done
killall play

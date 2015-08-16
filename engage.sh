play -n -c2 synth whitenoise band -n 100 20 band -n 50 20 gain +20 fade h 1 864000 1 2> /dev/null &
play -n -c2 synth whitenoise lowpass -1 100 lowpass -1 50 gain +7 2> /dev/null &
play -n -c2 synth whitenoise band -n 3900 50 gain -30 2> /dev/null &

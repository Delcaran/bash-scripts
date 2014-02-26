#!/bin/sh
#
# set default mixer volumes for ALSA
#
# Taken from the alsaconfig script.
#
amixer -s -q <<EOF
set Master 75% unmute
set Master -12dB
set 'Master Mono' 75% unmute
set 'Master Mono' -12dB
set Front 75% unmute
set Front -12dB
set PCM 90% unmute
set PCM 0dB
mixer Synth 90% unmute
mixer Synth 0dB
mixer CD 90% unmute
mixer CD 0dB
# mute mic
set Mic 0% mute
# ESS 1969 chipset has 2 PCM channels
set PCM,1 90% unmute
set PCM,1 0dB
# Trident/YMFPCI/emu10k1
set Wave 100% unmute
set Music 100% unmute
set AC97 100% unmute
# CS4237B chipset:
set 'Master Digital' 75% unmute
# Envy24 chips with analog outs
set DAC 90% unmute
set DAC -12dB
set DAC,0 90% unmute
set DAC,0 -12dB
set DAC,1 90% unmute
set DAC,1 -12dB
# some notebooks use headphone instead of master
set Headphone 75% unmute
set Headphone -12dB
set Playback 100% unmute
# turn off digital switches
set "SB Live Analog/Digital Output Jack" off
set "Audigy Analog/Digital Output Jack" off
EOF


#!/bin/bash
IMMAGINE=$1
growisofs -use-the-force-luke=dao -use-the-force-luke=break:1913760  -dvd-compat -speed=2 -Z /dev/dvd=${IMMAGINE}

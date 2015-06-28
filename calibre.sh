#!/bin/bash

# Upgrades and/or install Calibre
# It's the recomended metod of installation

sudo -v && \
    wget -nv -O- \
    https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | \
    sudo python -c \
    "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"

#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This script wraps i3status output and inject mail status, or just reports
# status on command line.  It is based on 'wrapper.py' script by Valentin
# Haenel, which could be found at:
# http://code.stapelberg.de/git/i3status/tree/contrib/wrapper.py
#
# To use it, ensure your ~/.i3status.conf contains this line:
#     output_format = "i3bar"
# in the 'general' section.
# Then, in your ~/.i3/config, use:
#     status_command i3status | path/to/check_mail.py ...
# In the 'bar' section.
#
# Or just run:
#     ./check_mail.py -1 ...
#
# Information on command line arguments (flags) may be obtained by running
#     ./check_mail.py -h
#
# © 2015 Dmitrij D. Czarkoff <czarkoff@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

import argparse
import json
import os
import os.path
import sys
import imaplib
import config
import string

def print_line(message):
    """ Non-buffered printing to stdout. """
    sys.stdout.write(message + '\n')
    sys.stdout.flush()

def read_line():
    """ Interrupted respecting reader for stdin. """
    # try reading a line, removing any extra whitespace
    try:
        line = sys.stdin.readline().strip()
        # i3status sends EOF, or an empty line
        if not line:
            sys.exit(3)
        return line
    # exit on ctrl-c
    except KeyboardInterrupt:
        sys.exit()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Check mailboxes.')
    parser.add_argument('-p', '--position', help='position of mail reports in i3bar status', type=int, default=0)
    args = parser.parse_args()

    # Skip the first line which contains the version header.
    print_line(read_line())

    # The second line contains the start of the infinite array.
    print_line(read_line())

    while True:
        line, prefix = read_line(), ''
        # ignore comma at start of lines
        if line.startswith(','):
            line, prefix = line[1:], ','

        j = json.loads(line)
        # insert information into the start of the json
        i = args.position
        f = open(config.mail_output, "r")
        for file_line in f:
            j.insert(i, json.loads(file_line))
            i += 1
        f.close()
        # and echo back new encoded json
        print_line(prefix+json.dumps(j))

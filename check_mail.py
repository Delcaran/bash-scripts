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

def check_mail(user, password, colors):
    """ Check mail in mailbox "label" and return report and color """
    mail = imaplib.IMAP4_SSL('imap.gmail.com')
    mail.login(user, password)
    # Out: list of "folders" aka labels in gmail.
    mail.select("inbox") # connect to inbox.
    result_all, data_all = mail.uid('search', None, "ALL")
    result_toread, data_toread = mail.uid('search', None, "UNSEEN")
    num_all = len(data_all[0].split())
    num_toread = len(data_toread[0].split())
    color = colors[0]
    report = str(num_toread)+"\\"+str(num_all)
    if result_all != 'OK' or result_toread != 'OK':
        color = colors[2]
    elif num_toread == 0:
        color = colors[0]
    else:
        color = colors[1]
    return report, color


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Check mailboxes.')
    parser.add_argument('-i', '--ignore', action='append', help='ignore named mailboxes', type=str, dest='ignore', metavar='mailbox')
    parser.add_argument('-0', '--nomail', help='text to print if no new mail found', type=str, default='')
    parser.add_argument('-g', '--good', help='color to use when there is no new mail', type=str, default='#00FF00')
    parser.add_argument('-d', '--degraded', help='color to use when there is new mail', type=str, default='#FFFF00')
    parser.add_argument('-b', '--bad', help='color to use when error was detected', type=str, default='#FF0000')
    args = parser.parse_args()

    colors = [args.good, args.degraded, args.bad]
    output = ""
    for mailbox in config.mailboxes:
        report, color = check_mail(mailbox["user"], mailbox["password"], colors)
        output += json.dumps({
                'name' : 'mail',
                'instance' : mailbox["user"],
                'full_text' : report,
                'color' : color
                    })
        output += '\n'
    f = open(config.mail_output, "w+")
    f.write(output)
    f.close()
    exit(0)

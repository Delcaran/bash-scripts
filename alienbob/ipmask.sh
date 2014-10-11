#!/bin/bash
# $Id: ipmask.sh,v 1.4 2010/01/05 19:03:22 root Exp root $
#
# Copyright (c) 2007-2009  Eric Hameleers, Eindhoven, The Netherlands
# All rights reserved.
#
#   Permission to use, copy, modify, and distribute this software for
#   any purpose with or without fee is hereby granted, provided that
#   the above copyright notice and this permission notice appear in all
#   copies.
#
#   THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
#   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#   IN NO EVENT SHALL THE AUTHORS AND COPYRIGHT HOLDERS AND THEIR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
#   USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
#   OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#   SUCH DAMAGE.
# ---------------------------------------------------------------------------
#
# Shell script replacement for the C-based ipmask program of Slackware Linux.
# Invocation:
#   ipmask.sh <decimal netmask> <decimal IP address>
# Returns:
#   <decimal broadcast address> <decimal network address>
#
#-----------------------------------------------------------------------------
# BTW vidar suggested this routine to calculate a netmask if you know
# the number of bits (take 26 as an example):
#   bits=26;
#   num=$[(0xffffffff<<(32-$bits))&0xffffffff];
#   echo "$[$num>>24].$[($num>>16)&0xff].$[($num>>8)&0xff].$[$num&0xff]"
#-----------------------------------------------------------------------------
MASK=${1:-""}
IPADDR=${2:-""}

# Require two parameters:
if [ -z "$MASK" -o -z "$IPADDR" ]; then
  echo "USAGE: ipmask.sh <decimal netmask> <decimal IP address>"
  exit 3
fi

# Only allow digits and the dot:
if [ "x$(echo $MASK |tr -d '0-9.')" != "x"  ]; then
  echo "Not a valid netmask"
  exit 1
fi
if [ "x$(echo $IPADDR |tr -d '0-9.')" != "x" ]; then
  echo "Not a valid IP address"
  exit 2
fi

# Split netmask into octets - no more, no less than four:
MASK=`echo $MASK |tr '.' ' '`
IND=0
for octet in $MASK; do
  if [ $octet -ge 0 -a $octet -le 255 ]; then
    MARR[$IND]=$octet
    IND=$(($IND + 1))
  else
    echo "Not a valid netmask"
    exit 1
  fi
done
if [ $IND -ne 4 ]; then
  echo "Not a valid netmask"
  exit 1
fi

# Split IP address into octets - no more, no less than four:
IPADDR=`echo $IPADDR |tr '.' ' '`
IND=0
for octet in $IPADDR; do
  if [ $octet -ge 0 -a $octet -le 255 ]; then
    IARR[$IND]=$octet
    IND=$(($IND + 1))
  else
    echo "Not a valid IP address"
    exit 2
  fi
done
if [ $IND -ne 4 ]; then
  echo "Not a valid IP address"
  exit 2
fi

# Bitwise combine IP address and netmask to produce broadcast/network:
for i in 0 1 2 3; do
  BARR[$i]=$((${IARR[$i]} | $((~${MARR[$i]}+256))))
  NARR[$i]=$((${IARR[$i]} & ${MARR[$i]}))
done

# Finally, spit out broadcast and network addresses:
echo -n "${BARR[*]}"|tr ' ' '.'
echo -n " "
echo "${NARR[*]}"|tr ' ' '.'


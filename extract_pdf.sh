#!/bin/bash
function pdfpextr()
{
    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
        -dFirstPage=${1} \
        -dLastPage=${2} \
        -sOutputFile=${3%.pdf}_p${1}-p${2}.pdf \
        ${3}
}

INIZIO=$1
FINE=$2
FILE=$3

pdfpextr ${INIZIO} ${FINE} "${FILE}"

exit 0

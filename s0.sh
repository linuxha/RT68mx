#!/bin/bash

if [ $# -ne 1 ]; then
    echo "S0 Generator, converts text to S0 Record"
    echo "$0 \"String to convert\""
    exit 1
fi


STR=$(sed -e 's/ /\\ /g' <<< "${1}")
STR=$(while read -n 1 a; do printf "%02X" "'$a";done <<< "${STR}")
L=$(( (${#STR}/2) + 3 ))
CHKSUM=${L}

if [ $L -gt 255 ]; then
    echo "S0 string is too long (${L} chars)"
    exit 1
fi

while read -n 2 a
do
    CHKSUM=$(($CHKSUM+0x${a}))
done <<< "${STR}"

CHKSUM=$(( 255 - (${CHKSUM}&255) ))
printf "S0%02X0000%s%02X\n" ${L} "${STR}" ${CHKSUM}

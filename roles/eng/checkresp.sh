#!/bin/bash

FILENAME=$1
#set -x

grep -aqm1 'SUBMIT_SM ' $FILENAME
if [ 0 -ne $? ]; then echo "Error: no submits found, exiting."; exit 1; fi

CHECKLEN=$(grep -am1 'SUBMIT_SM ' $FILENAME  | awk -F '[ ,]' '{print $5}')
#echo "$CHECKLEN"

if [[ 'SUBMIT_SM' == "$CHECKLEN" ]]
    then
        echo "Long log format detected."
        DELTA0="$(for i in $(grep -am1100 'SUBMIT_SM ' $FILENAME | tail -1000 | awk -F '[ ,]' '{print $6}'); do grep -aE "SUBMIT_SM.* $i$" $FILENAME | cut -d ' ' -f 2 | while read line; do date -d $line +%s.%3N; done | paste -sd-  | bc ; done | sort | sed 's/-\./0./g' | sed 's/-//g' )"
    else
        echo "Short log format detected."
        DELTA0="$(for i in $(grep -am1100 'SUBMIT_SM ' $FILENAME | tail -1000 | awk -F '[ ,]' '{print $5}'); do grep -aE "SUBMIT_SM.* $i," $FILENAME | cut -d ' ' -f 2 | while read line; do date -d $line +%s.%3N; done | paste -sd-  | bc ; done | sort | sed 's/-\./0./g' | sed 's/-//g' )"
fi

DELTA=$(echo "$DELTA0" | grep -v "[0-9][0-9][0-9][0-9][0-9][0-9][0-9]")

SCOPE=`echo "$DELTA" | wc -l`
echo "Number of submits scanned: $SCOPE"
echo ''

HALFSIZE=$(echo "$SCOPE / 2" | bc)
QUARTSIZE=$(echo "$SCOPE / 4" | bc)


AVG=$(echo "$(echo "$DELTA" | awk '{sum+=$1} END {print sum}') * 1000 / $SCOPE" | bc)
MED=$(echo "$(echo "$DELTA" | sort -gr | tail -$HALFSIZE | head -1) * 1000 / 1" | bc)
QUA=$(echo "$(echo "$DELTA" | sort -gr | head -$QUARTSIZE | tail -1) * 1000 / 1" | bc)
echo "AVG_LATENCY,ms: $AVG" | column -t
echo "MED_LATENCY,ms: $MED" | column -t
echo "75%AREBELOW,ms: $QUA" | column -t



#echo -e $DELTA | uniq -c | sed 's/-\./0./g' | sed 's/-//g' | awk '{print $2 " " $1}' | column -t | sort -g

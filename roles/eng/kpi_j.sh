#! /bin/bash

NUMLINES=1000

THRPMEM="$(join -j 2 -o 1.1,1.2,1.4,1.6,2.3,2.4 <(tail -$NUMLINES /opt/just/log/stat/throughput.log | sort -k 2) <(tail -$NUMLINES /opt/just/log/stat/system.log | sort -k 2 | awk '{print $1" "$2" "$4/1024**2" "$6/1024**2'}))"
THRPMEMCPU=$(join -j 2 -o 1.1,1.2,1.3,1.4,1.5,1.6,2.3,2.4,2.5,2.6 <(echo "$THRPMEM") <(tail -$NUMLINES /opt/just/log/stat/schedulers.log | sort -k 2 | awk '{print $1" "$2" "$4+$5+$6+$7+$8+$9+$10+$11+$12+$13+$14+$15+$16+$17+$18+$19+$20+$21+$22+$23+$24}'))

echo "date time rpsin rpsout memtotMB memallMB CPU%
$THRPMEMCPU
"

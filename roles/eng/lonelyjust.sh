#! /bin/bash

#31315
# Load test for standalone Just instance

#DUMP='258_900K.qdump'
#INJECTCOUNT=250
DUMP='200K_FUN.qdump'
INJECTCOUNT=200000
#TESTDIR=~/
CSVSTATS=~/$(date +%F_%H%M)_jloadtest.csv
LOGFILE=~/$(date +%F_%H%M%S)_jloadtest.log
GTWID='A285681F-D336-E011-AD83-D8D385BCC314.5'
TARGETQUEUE='pmm.just.gateway.A285681F-D336-E011-AD83-D8D385BCC314.5'

IPRABBIT='188.166.184.205'
IPSMSC=('10.130.40.168' '10.130.42.244')

function killemall {
    ps aux | grep $1 | grep -v -e 'grep' -e 'lonel' | awk '{print $2}' | while read line ; do kill -term $line ; done ; ps aux | grep $1 | grep -v -e 'grep' -e 'lonel' | awk '{print $2}' | while read line ; do kill -kill $line ; done
}

stopjust() {
    sudo -u bms /opt/just/bin/just stop
    sleep 15
    ps aux | grep just | grep -v -e 'grep' -e 'lonely'
    killemall '\"progname just\"'
    ps aux | grep -v -e 'grep' -e 'lonely' -e 'daemon' | grep 'progname just' > /dev/null ; if [ 0 -ne $? ] ; then echo "Just STOPPED" ; else echo "Unable to stop Just, exiting..." ; exit ; fi
}

startjust() {
    sudo -u bms /opt/just/bin/just start
    sleep 5
    ps aux | grep -v -e 'grep' -e 'lonely' -e 'daemon' | grep 'progname just' > /dev/null ; if [ 0 -eq $? ] ; then echo "Just STARTED" ; else echo "Unable to start Just, exiting..." ; exit ; fi
}

cleanup() {
    stopjust
    rm -rf /opt/just/data/mnesia/*
    rm -rf /opt/just/data/dedup/*
    cp ~/FALLBACK.BUP /opt/just/data/mnesia/
    #cp -ax /opt/j3_init_data/* /opt/just/data/
    #chown bms:bms -R /opt/just/data/*
    rm -rf /opt/just/log/*
    ssh $IPRABBIT -- rmq_tool purge $TARGETQUEUE
}

# Log HW configuration
echo "MEMORY: $(free -m | head -2 | tail -1 | awk '{print $2}') M" >> $LOGFILE
echo "$(lscpu | grep -e "^CPU(" -e 'MHz' -e cache)" >> $LOGFILE

# Log test data type
echo "Dump name: $DUMP" >> $LOGFILE

# Log key gateway configs
grep -e 'concurrent_' -e 'size' /opt/just/data/odbc.2.dump  >> $LOGFILE

# Stop just and cleanup just data to enable repetitious queue injection
cleanup

# Convert odbc dump
~/convert_j3_config

# Inject queue
#cp ~/$DUMP /opt/rmq_tool/dumps/
ssh $IPRABBIT -- rmq_tool restore $TARGETQUEUE ~/$DUMP 1 $INJECTCOUNT
#verify injection
sleep 5
QSIZE=$(ssh $IPRABBIT -- rabbitmqctl -n rabbit@rabbit-centos-512mb-sgp1-02 list_queues name messages | column -t | grep -i $TARGETQUEUE | awk '{print $2}')
if [ $QSIZE -eq 0 ] ; then echo "Queue=0, queue injection seems to have failed, exiting..." ; exit ; else echo "Number of messages (batches) in the queue: $QSIZE" ; fi

# Start just
startjust
# Log start time
STARTTIME=$(date +%F" "%H:%M)
echo "Started at: $STARTTIME" >> $LOGFILE

# Wait until the queue is processed
#i=0
while [ $QSIZE -ne 0 ]
do
sleep 10
QSIZE=$(ssh $IPRABBIT -- rabbitmqctl -n rabbit@rabbit-centos-512mb-sgp1-02 list_queues name messages | column -t | grep -i $TARGETQUEUE | awk '{print $2}')
echo "Queue: $QSIZE"
done

FINTIME=$(date +%F" "%H:%M)
echo "Finished at: $FINTIME" >> $LOGFILE

# Log stats
echo "Average throughput rate: $(~/kpi_j.sh | awk '{sum+=$4}END{print sum/NR}') mps" >> $LOGFILE
~/kpi_j.sh | sed 's/   //g' | sed 's/ /,/g' > $CSVSTATS
~/kpi_j.sh | column -t >> $LOGFILE

# Log stats (For versions < 3.7.3)

~/kpi_j.sh | grep [0-9]
if [ 0 -ne $? ]
then
~/getThroughputSlices | tail -250 | column -t >> $LOGFILE
## STATS ##
RAWDATA=$(grep -a 'out:' $LOGFILE | grep -a 'in:' | awk '{print $NF}')
SCOPE=$(echo "$RAWDATA" | wc -l)
DATASET="$(echo "$RAWDATA" | head -$(echo "$SCOPE - 20" | bc) | tail -$(echo "$SCOPE - 40" | bc))"
SCOPE=$(echo "$DATASET" | wc -l)
AVGTHRP=$(echo "$(echo "$DATASET" | paste -sd+ | bc) / $SCOPE" | bc)
MAXTHRP=$(echo "$DATASET" | sort -gr | head -1)
AMRATIO=$((100*$AVGTHRP/$MAXTHRP))
echo "SCOPE,seconds: $SCOPE" >> $LOGFILE
echo "AVGTHRP,mps: $AVGTHRP" >> $LOGFILE
echo "MAXTHRP,mps: $MAXTHRP" >> $LOGFILE
echo "AMRATIO,%: $AMRATIO" >> $LOGFILE
fi

# Backup raw stats
mkdir ~/$(date +%F"_"%H:%M)_stat ; cp /opt/just/log/stat/* ~/$(date +%F"_"%H:%M)_stat/

# Check latency (if latency is > 1000ms, then it is recommended to repeat the test with a smppsink node of increased capacity, unless you're running negative tests)
for i in "${IPSMSC[@]}"
do
    SMPPLOGFILE="$(ls /opt/just/log/`date +%F`/ | grep tran | grep -v present | tail -50 | grep -m1 $i)"
    echo "Latency SMSC $i: $(~/checkresp.sh /opt/just/log/`date +%F`/$SMPPLOGFILE | grep -a AVG)" >> $LOGFILE
done

## REPORT ##
cat $LOGFILE | tr -d "\015" | mail -s "Standalone Just load test" -a $CSVSTATS -a /opt/just/data/odbc.2.dump -a /opt/just/etc/app.config d.maltsev@dev1team.net
#,a.sizov@dev1team.net

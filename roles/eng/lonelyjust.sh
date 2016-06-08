#! /bin/bash

#31315
# Load test for standalone Just instance

DUMP='30K50M.qdump'
#TESTDIR=~/
LOGFILE=~/$(date +%F_%H%M%S)_jloadtest.log
GTWID='A285681F-D336-E011-AD83-D8D385BCC314.5'
TARGETQUEUE='pmm.just.gateway.A285681F-D336-E011-AD83-D8D385BCC314.5'

IPRABBIT='127.0.0.1'
IPSMSC='127.0.0.1'

stopjust() {
    sudo -u bms /opt/just/bin/just stop
    sleep 15
    ps aux | grep -v -e 'grep' -e 'lonely' | grep just > /dev/null ; if [ 0 -ne $? ] ; then echo "Just STOPPED" ; else echo "Unable to stop Just, exiting..." ; exit ; fi
}

startjust() {
    sudo -u bms /opt/just/bin/just start
    sleep 5
    ps aux | grep -v -e 'grep' -e 'lonely' | grep just > /dev/null ; if [ 0 -eq $? ] ; then echo "Just STARTED" ; else echo "Unable to stop Just, exiting..." ; exit ; fi
}

cleanup() {
    stopjust
    rm -rf /opt/just/data/mnesia/*
    rm -rf /opt/just/data/dedup/*
    #cp -ax /opt/j3_init_data/* /opt/just/data/
    #chown bms:bms -R /opt/just/data/*
    rm -rf /opt/just/log/*
    /opt/rmq_tool/rmq_tool purge $TARGETQUEUE
}

# Log HW configuration
echo "MEMORY: $(free -m | head -2 | tail -1 | awk '{print $2}') M" >> $LOGFILE
echo "$(lscpu | grep -e "^CPU(" -e 'MHz' -e cache)" >> $LOGFILE

#Log test data type
echo "Dump name: $DUMP" >> $LOGFILE

# Stop just and cleanup just data to enable repetitious queue injection
cleanup

# Inject queue
cp ~/$DUMP /opt/rmq_tool/dumps/
/opt/rmq_tool/rmq_tool restore $TARGETQUEUE ~/$DUMP
#verify injection
sleep 5
QSIZE=$(ssh $IPRABBIT -- /opt/rabbitmq_server-3.6.1/sbin/rabbitmqctl -n rabbit@localhost list_queues name messages | column -t | grep -i $TARGETQUEUE | awk '{print $2}')
if [ $QSIZE -eq 0 ] ; then echo "Queue=0, queue injection seems to have failed, exiting..." ; exit ; else echo "Number of messages (batches) in the queue: $QSIZE" ; fi

# Start just
startjust
# Log start time
STARTTIME=$(date +%F" "%H:%M)
echo "Started at: $STARTTIME" >> $LOGFILE

# Wait until the queue is processed
i=0
while [ $QSIZE -ne 0 ]
do
sleep 10
QSIZE=$(ssh $IPRABBIT -- /opt/rabbitmq_server-3.6.1/sbin/rabbitmqctl -n rabbit@localhost list_queues name messages | column -t | grep -i $TARGETQUEUE | awk '{print $2}')
echo "Queue: $QSIZE"
done

FINTIME=$(date +%F" "%H:%M)
echo "Finished at: $FINTIME" >> $LOGFILE

# Log stats
~/kpi_j.sh >> $LOGFILE

# Backup raw stats
mkdir ~/$(date +%F"_"%H:%M)_stat ; cp /opt/just/log/stat/* ~/$(date +%F"_"%H:%M)_stat/

# Check latency (if latency is > 1000ms, then it is recommended to repeat the test with a smppsink node of increased capacity, unless you're running negative tests)
for i in $IPSMSC
do
    SMPPLOGFILE="$(ls /opt/just/log/`date +%F`/ | grep tran | grep -v present | tail -50 | grep -m1 $i)"
        echo "Latency SMSC $i: $(~/checkresp.sh /opt/just/log/`date +%F`/$SMPPLOGFILE | grep -a AVG)" >> $LOGFILE
done

## REPORT ##
cat $LOGFILE | tr -d "\015" | mail -s "Standalone Just load test" d.maltsev@dev1team.net
#,a.sizov@dev1team.net

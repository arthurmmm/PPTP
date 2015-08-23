#!/bin/bash
# Example: autopon PPTPSERVER

DIR=`dirname $0`
TARGET=$1
SUCCESS_STRING=^"remote IP address "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$
FAIL_STRING="status = 0x0"
CONNECT_STRING="Connect: ppp0"
ATTEMPT=5 # Attempt limits
TMOUT=20 # Timeout threshold
LOG=$DIR'/autopon.session'

while [[ $ATTEMPT > 0 ]]; do
    export LOOP_PID=$$
    echo ">>> $ATTEMPT attempts remain..."
    nohup /usr/sbin/pppd call $TARGET > $LOG &
    ATTEMPT=`expr $ATTEMPT - 1`
    
    # Monitor pppd call
    tail -f $LOG | while read LINE; do
        TAILF_PID=`ps -aux | grep "tail -f "$LOG | grep -v grep | awk '{print $2}'`
        echo $LINE

        # Setup a timer. If no fresh output after $TMOUT, kill the pppd call and start next attempt
        # Each time new output comes, kill the previous timer
        if [ $EXIST_TIMEOUT ]; then
            kill $EXIST_TIMEOUT > /dev/null 2>&1
        fi
        PPPD_PID=`ps -aux | grep "pppd call" | grep -v grep | awk '{print $2}'`
        Timeout $TMOUT $PPPD_PID > /dev/null 2>&1 &
        export EXIST_TIMEOUT=$!
        
        # Succesfully connect the server, terminate the script
        if [[ $LINE =~ $SUCCESS_STRING ]]; then
            kill $EXIST_TIMEOUT > /dev/null 2>&1
            echo '>>> Complete!'
            kill $TAILF_PID
            kill $LOOP_PID
            break
        # Failed to connect, start next attempt
        elif [[ $LINE =~ $FAIL_STRING ]]; then
            kill $EXIST_TIMEOUT > /dev/null 2>&1
            EXIST_TIMEOUT=''
            echo '>>> Failed.. Retry after 3s..'
            sleep 3
            kill `ps -aux | grep "tail -f "$LOG | grep -v grep | awk '{print $2}'` > /dev/null 2>&1
        fi
    done 2>/dev/null
done

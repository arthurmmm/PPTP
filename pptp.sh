#!/bin/bash

start(){
    callnum=`ps -aux |grep 'pppd call' | grep -v grep | wc -l`
    if [ $callnum -eq 0 ]; then
        echo 'PPTP is not running!'
        echo 'Please use "pon <Host name>" to start PPTP then run this script to setup route table.'
        echo 'Use "pptp.sh list" to get all available host'
        exit 1
    fi
    echo 'Setting DNS...'
    mv /etc/resolv.conf /etc/_resolv.conf
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf
    echo 'Finish DNS setting...'
    echo 'Setting PPTP route...'
    ip route del default
    ip route add default dev ppp0
    echo 'Finish, current route table:'
    route -n
}

start(){
    list
    echo -n 'Please choose:'
    read TARGET
    
    autopon $TARGET
        
    callnum=`ps -aux |grep 'pppd call' | grep -v grep | wc -l`
    if [ $callnum -eq 0 ]; then
        echo '>>> Failed to start PPTP!'
        exit 1
    fi
    echo 'Setting DNS...'
    cp /etc/resolv.conf /etc/_resolv.conf
    echo 'nameserver 8.8.8.8' > /etc/resolv.conf
    echo 'Finish DNS setting...'
    echo 'Setting PPTP route...'
    ip route del default
    ip route add default dev ppp0
    echo 'Finish, current route table:'
    route -n
}

list(){
    echo '==== Available Hosts ===='
    ls -l /etc/ppp/peers | egrep -v "ppp|pppoatm|pppoe|pppoe-rp|pptp|total" | awk '{print $9}'
    echo '========================='
}

stop(){
    echo 'Stopping PPTP...'
    poff `ps -aux |grep 'pppd call' | grep -v grep | awk '{print $13}'`
    echo 'Resume DNS...'
    cp /etc/_resolv.conf /etc/resolv.conf
    echo 'Finish resuming DNS...'
    echo 'Setting default route...'
    ip route del default
    ip route add default via 192.168.111.1 dev eno16777736  proto dhcp
    echo 'Finish, current route table:'
    route -n
}

case $1 in 
    start)
        start
        ;;
    stop)
        stop
        ;;
    list)
        list
        ;;
esac

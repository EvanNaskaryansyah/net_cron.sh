#!/bin/bash
# Created By : Maulana Ibrahim
# 15-11-2019
#-----------------------------
inet=8.8.8.8
dt=`date "+%Y-%m-%d %H:%M:%S"`
dr=`ip route show | grep "default"`
if [ -z "$dr" ];then
echo "$dt | Default route is not available"
exit 0
fi
tping=`ping -c 5 $inet`
ploss=`echo $tping : | grep -oP '\d+(?=% packet loss)'`
if [ "$ploss" -eq "100" ];then
echo "$dt | Internet is disconnected"
exit 0
else
echo "$dt | Internet is connected"
fi
hvpn=`ip route show | grep "10.99.99.99"`
if [ -z "$hvpn" ];then
echo "$dt | VPN is disconnected, reconnecting .."
service xl2tpd restart
sleep 2
echo "c vpn-connection" > /var/run/xl2tpd/l2tp-control
else
echo "$dt | VPN is connected"
fi

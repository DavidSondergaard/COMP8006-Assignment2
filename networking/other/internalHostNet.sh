#!/bin/bash

## Configure this area first
intHost="e8"
intIp="192.168.10.2"

fwIp="192.168.10.1"
sudo ifconfig $intHost $intIp up
sudo route add default $fwIp
ping 192.168.10.1 -c 3

# Enable inthost

netstat -rt

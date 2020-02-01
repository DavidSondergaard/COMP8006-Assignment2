#!/bin/bash

'''
#cat > /etc/resolv.conf << EOF
#nameserver 192.168.10.1
#options edns0
#EOF
'''


intInterface=en8
sudo ip route flush dev $intInterface
sudo ifconfig $intInterface 192.168.10.2 up
sudo ip route add 192.168.10.1 dev $intInterface
sudo ip route add default via 192.168.10.1
sudo ip route add 192.168.10.0/24 via 192.168.10.1 dev $intInterface
sudo route add 192.168.10.0/24 via 192.168.10.1 dev $intInterface

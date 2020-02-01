#!/bin/bash

'''
#cat > /etc/resolv.conf << EOF
#nameserver 192.168.10.1
#options edns0
#EOF
'''


intInterface=en8
ip route flush dev $intInterface
ifconfig $intInterface 192.168.10.2 up
ip route add 192.168.10.1 dev $intInterface
ip route add default via 192.168.10.1
sudo route add default gw 192.168.10.1 $intInterface
ip route add 192.168.10.0/24 via 192.168.10.1 dev $intInterface
#sudo route add default gw 192.168.10.1 $intInterface

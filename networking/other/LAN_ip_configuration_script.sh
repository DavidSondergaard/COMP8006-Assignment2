#!/bin/bash

####################################################################
#                                                                  #
#  Purpose:  To setup the network connections for Lan computers    #
#            that are protected from WAN via the Firewall Computer #
#                                                                  #
####################################################################

#Lan Computer's Configuration
LanComputerInterface=en8
LanComputerIP=192.168.10.2
LanComputerSubnetIP=192.168.10.0/24

#Reference to Outbound Connections
LanNameserverIp=192.168.10.1
LanOutboundDefaultIP=192.168.10.1

# TODO:
cat > /etc/resolv.conf << EOF
nameserver $LanNameserverIp
options edns0
EOF


ip route flush dev $LanComputerInterface
ifconfig $LanComputerInterface $LanComputerIP up
ip route add $LanOutboundDefaultIP dev $LanComputerInterface
ip route add default via $LanOutboundDefaultIP
ip route add $LanComputerSubnetIP via $LanOutboundDefaultIP dev $LanComputerInterface
route add $LanComputerSubnetIP via $LanOutboundDefaultIP $LanComputerInterface

#!/bin/bash

####################################################################
#                                                                  #
#  Purpose:  To setup the network connections for the fw computer. #
#                                                                  #
####################################################################

#LAN HOST CONFIGURATION
Lan1ComputerInterface=eno0
Lan1SubnetIP=192.168.10.0
Lan1Host2IP=192.168.10.2
Lan1Host3IP=192.168.10.3
Lan1Host4IP=192.168.10.4

#ADMIN HOST CONFIGURATION
Lan2ComputerInterface=eno2
Lan1SubnetIP=192.168.20.0
Lan1Host2IP=192.168.20.2

#FIREWALL HOST CONFIGURATION
LanNameserverIp=192.168.10.1
DefaultLan1OutboundIP=192.168.10.1
DefaultLan2OutboundIP=192.168.20.1
DefaultWanOutboundIP=192.168.1.254



#
# TODO:
#cat > /etc/resolv.conf << EOF
#nameserver $LanNameserverIp
#options edns0
#EOF

#CLEAR rules
ip route flush dev $LanComputerInterface

#SET outbound interface
ifconfig $LanComputerInterface $LanComputerIP up

#ENABLE IP forwarding between interfaces
echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward



#ADD FIREWALL DEFAULT UNKNOWN IP GATEWAY
route add -net  192.168.0.0 netmask 255.255.255.0 gw WanOutboundDefaultIP
#ADD FIREWALL DEFAULT ROUTE TO ORCHARD SUBNET
route add -net 192.168.10.0/24 gw $LanOutboundDefaultIP
#ADD FIREWALL DEFAULT ROUTE TO WATERWAYS SUBNET
route add -net 192.168.20.0/24 gw $AdminOutboundDefaultIP


#ADD FIREWALL DEFAULT ROUTE TO WATERWAYS SUBNET
ip route add $LanComputerSubnetIP via $LanOutboundDefaultIP dev $LanComputerInterface

#
route add $LanComputerSubnetIP via $LanOutboundDefaultIP $LanComputerInterface


###################################################################
#                                                                 #
#                    SETUP HOSTS AND ALIASES                      #
#                                                                 #
###################################################################
#
# IP ---------- FQDN ----------------------------------- ALIASES
#
#WAN AND LOCAL INTERFACES
#127.0.0.1       localhost                                planet3-landing
#192.168.1.87    planet3                                  planet3-if0
#192.168.1.254   galaxies                                 galaxies-wan            
#
#FIREWALL INTERNAL INTERFACE FOR SUBNET 10
#172.16.10.1     orchards.bcit8006-pts20-assign2.com      orchards planet3-if1
#LAN HOST 2
#72.16.10.2     apples.bcit8006-pts20-assign2.com         apples
#LAN HOST 3
#72.16.10.3     oranges.bcit8006-pts20-assign2.com        oranges
#LAN HOST 4
#72.16.10.4     pears.bcit8006-pts20-assign2.com          pears

#ADMIN INTERNAL HARDWIRED INTERFACE
#FIREWALL INTERFACE FOR SUBNET 20
#172.16.20.1     waterways.bcit8006-pts20-assign2.com     waterways planet3-if2 
#ADMIN HOST INTERFACE
#172.16.20.2     sharkbait.bcit8006-pts20-assign2.com     sharkbait

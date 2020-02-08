#!/bin/bash

####################################################################
#                                                                  #
#  Purpose:  To setup the network connections for the fw computer. #
#                                                                  #
####################################################################


IPExactMatch=255.255.255.255
#LAN HOST CONFIGURATION
Lan1Host2InterfaceName=enp60s0
Lan1Host2Name=apples
Lan1Host2InterfaceIP=192.168.10.2
Lan1DefaultGateway=192.168.10.1
Lan1SubnetIP=192.168.10.0
Lan1SubnetMask=255.255.255.0

Lan1Host3InterfaceIP=UNASSIGNED

#FIREWALL HOST CONFIGURATION
FWLan1InterfaceName=enp0s20f0u3u3
FWLan1SubnetName=orchards
FWLan1InterfaceIP=192.168.10.1
FWLan1NameserverIp=192.168.10.1
FWLan1SubnetIP=$Lan1SubnetIP
FWLan1SubnetMask=$Lan1SubnetMask

FWWanInterfaceName=enp0s20f0u2
FWDefaultWanOutboundName=galaxies
FWWanInterfaceIP=192.168.1.130
FWWanDefaultGateway=192.168.1.254
FWWanSubnetIP=192.168.1.0
FWWanSubnetMask=255.255.255.0

if [  "$1" = "firewall"  ]
    then
            echo "setting firewall config because $1 was passed"
        #CLEAR rules
            ip route flush dev $FWLan1InterfaceName
        #SET outbound interface
            ifconfig $FWLan1InterfaceName $FWLan1InterfaceIP up
        #ENABLE IP forwarding between interfaces
            echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward
        #ADD FIREWALL DEFAULT UNKNOWN IP GATEWAY TO WAN INTERFACE
            route add -net $FWWanSubnetIP netmask $FWWanSubnetMask gw $FWWanInterfaceIP
        #FORCE ALL SUBNET TRAFFIC TO USE FIREWALL INTERFACE TO ACCESS LAN1 ORCHARD SUBNET
            route add -net $FWLan1SubnetIP netmask $FWLan1SubnetMask gw $FWLan1InterfaceIP
    elif [  "$1" = "lan1"  ]
    then
        #CLEAR rules
            echo "setting lan1 config because $1 was passed"
            ip route flush dev $Lan1Host2InterfaceName
        #SET outbound interface
            ifconfig $Lan1Host2InterfaceName $Lan1Host2IP up
        #ENABLE IP forwarding between interfaces
            ip route add $Lan1DefaultGateway dev $Lan1Host2InterfaceName
        #SEND TRAFFIC TO FIREWALL IF NO VALID MATCH
            ip route add default via $Lan1DefaultGateway
        #SEND TRAFFIC TO FIREWALL FIRST IF REQUEST IS FOR A COMPUTER IN THIS SUBNET
            ip route add $Lan1SubnetIP netmask $FWLan1SubnetMask via $Lan1DefaultGateway dev $Lan1Host2InterfaceName
            route add $Lan1SubnetIP netmask $FWLan1SubnetMask via $Lan1DefaultGateway $Lan1Host2InterfaceName
    else
        #error
        echo "$1 is not a valid match.  Please try again."
fi





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

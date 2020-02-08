#!/bin/bash

#########################################################################
#                                                                       #
#  Purpose:  To setup the network connections for lan,fw,wan computers. #
#                                                                       #
#########################################################################


##### TOOLS ####
ITBL="/sbin/iptables"
IFC="/sbin/ifconfig"
RTE="/sbin/route"
IP="/usr/bin/ip"
TEE="/usr/bin/tee"

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

#LAN HOST CONFIGURATION
Wan1Host2InterfaceName=eth0
Wan1Host2Name=attackers
Wan1Host2InterfaceIP=192.168.1.135
Wan1DefaultGateway=192.168.1.254
Wan1SubnetIP=192.168.1.0
Wan1SubnetMask=255.255.255.0

if [  "$1" == "firewall"  ]
    then
            echo "setting firewall config because $1 was passed"
        #CLEAR rules
            ip route flush dev $FWLan1InterfaceName
        #SET outbound interface
            ifconfig $FWLan1InterfaceName $FWLan1InterfaceIP up
        #ENABLE IP forwarding between interfaces
            echo "1" | tee /proc/sys/net/ipv4/ip_forward
        #ADD FIREWALL DEFAULT UNKNOWN IP GATEWAY TO WAN INTERFACE
            echo add -net $FWWanSubnetIP netmask $FWWanSubnetMask gw $FWWanInterfaceIP
        #FORCE ALL SUBNET TRAFFIC TO USE FIREWALL INTERFACE TO ACCESS LAN1 ORCHARD SUBNET
            route add -net $FWLan1SubnetIP netmask $FWLan1SubnetMask gw $FWLan1InterfaceIP
        val1=`(nmcli -t con show | grep $FWLan1InterfaceName | awk -F ":" '{ print $1}')`
        echo "$val1"
        nmcli con modify $val1 ipv4.dns $FWWanDefaultGateway

    elif [  "$1" = "lan1"  ]
    then
        #CLEAR rules
            echo "setting lan1 config because $1 was passed"
            ip route flush dev $Lan1Host2InterfaceName
        #SET outbound interface
            echo "setting A"
            ifconfig $Lan1Host2InterfaceName $Lan1Host2InterfaceIP up
        #ENABLE IP forwarding between interfaces
            echo "setting B"
            ip route add $Lan1DefaultGateway dev $Lan1Host2InterfaceName
        #SEND TRAFFIC TO FIREWALL IF NO VALID MATCH
            echo "setting C"
            route  add default gw $Lan1DefaultGateway
        #SEND TRAFFIC TO FIREWALL FIRST IF REQUEST IS FOR A COMPUTER IN THIS SUBNET
    elif [  "$1" = "wanClient"  ]
    then
        #CLEAR rules
            echo "setting wanClient config because $1 was passed"
            #ip route flush dev $Lan1Host2InterfaceName
        #SET outbound interface
            
            ifconfig $Wan1Host2InterfaceName $Wan1Host2InterfaceIP up
        #ROUTING TRAFFIC TO FIREWALL THROUGH SUBNET TO CLIENT LAN
            echo "setting A"
            route add default gw $Wan1DefaultGateway
            echo "setting B"
            route add default gw $Wan1DefaultGateway dev $Wan1Host2InterfaceName
            echo "setting C"
            route add default gw $Wan1DefaultGateway via $FWWanInterfaceIP dev $Wan1Host2InterfaceName
            echo "setting D"
            route add default gw $Wan1DefaultGateway gw $FWWanInterfaceIP
    else
        #error
        echo "$1 is not a valid match.  Please try again."
fi

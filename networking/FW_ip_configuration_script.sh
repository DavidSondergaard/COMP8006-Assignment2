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
            echo "setting A"
            ifconfig $Lan1Host2InterfaceName $Lan1Host2InterfaceIP up
        #ENABLE IP forwarding between interfaces
            echo "setting B"
            ip route add $Lan1DefaultGateway dev $Lan1Host2InterfaceName
        #SEND TRAFFIC TO FIREWALL IF NO VALID MATCH
            echo "setting C"
            route add default gw $Lan1DefaultGateway
        #SEND TRAFFIC TO FIREWALL FIRST IF REQUEST IS FOR A COMPUTER IN THIS SUBNET
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

###
# THIS PRINTS THE NAMESERVERS OF THE FIREWALL COMPUTER
#
# nmcli -o | grep servers | awk '{print $2}'

# TO ADD ANOTHER DNS

# nmcli -t con | grep enp0s20f0u2 | awk -F ":" '{print $1}'

##### val1=`(jmcli -t con show | grep enp | awk -F ":" '{ print $1}')`; nmcli con modify $val1 +ipv4.dns "1.2.3.6"


# nmcli con modify "Wired connection 2" +ipv4.dns "192.168.1.254"

# nmcli con down "Wired connection 2"
# nmcli con up "Wired connection 2"
###





# sudo iptables -t nat -A POSTROUTING -o enp0s20f0u2 -j MASQUERADE
# sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# sudo iptables -A FORWARD -i enp0s20f0u3u3 -o enp0s20f0u2 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
# sudo iptables -A FORWARD -i enp0s20f0u2 -o enp0s20f0u3u3 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT






###OUTSIDE OF NETOWRK!!!

# TO ACCESS INSIDE OF NETOWRK FROM OUTSIDE, YOIU NEED TO SETUP FORWARDING FROM OUTSIDE TO INSIDE. 
# THEN, YOU ALSO NEED TO SETUP THE ROUTING TABLES ON THE WAN COMPUTER TO RECOGNIZE THAT THE
# SUBNET IS ACCESSED FROM THE FW WAN SIDE INTERFACE

# SO ON THE COMPUTER THAT IS ON THE WAN, ENTER:  

#route add -net 192.168.10.0/24
#route add -net 192.168.10.0/24 dev eth0
#route add -net 192.168.10.0/24 via 192.168.1.130 dev eth0
#route add -net 192.168.10.0/24 gw 192.168.1.130
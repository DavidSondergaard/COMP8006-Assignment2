#!/bin/bash

####################################################################
#                                                                  #
#  Purpose:  To setup the firewall on the firewall computer.       #
#                                                                  #
####################################################################

#############################################
#	USER DEFINED VARIABLES              #
#############################################

##### NETWORK INTERFACES ####
#Outside Interface
WAN_INTERFACE="eno1"
WAN_ADDRESS="192.168.1.13"
WAN_CHANGE_IP=0

#Computer Interface
LOCAL_INTERFACE="lo"
LOCAL_ADDRESS="127.0.0.1"

#Internal LAN Interface
LAN_INTERFACE="eno2"
LAN_ADDRESS="192.168.10.2"
LAN_CHANGE_IP=0

#Seperate Admin Port
ADMIN_INTERFACE=""
ADMIN_ADDRESS=""
ADMIN_CHANGE_IP=0


#############################################
#############################################
######                                 ######
######    DO NOT EDIT BELOW THIS BOX   ######
######                                 ######
#############################################
#############################################


#############################################
#           CUSTOMIZE INTERFACES            #
#############################################

if [ $WAN_CHANGE_IP == 1 ]
then
	ifconfig $WAN_INTERFACE $WAN_ADDRESS up
fi

if [ $LAN_CHANGE_IP == 1 ]
then
	ifconfig $LAN_INTERFACE $LAN_ADDRESS up
fi

if [ $ADMIN_CHANGE_IP == 1 ]
then
	ifconfig $ADMIN_INTERFACE $ADMIN_ADDRESS up
fi


#############################################
#      SYSTEM SETUP FOR FORWARDING          #
#############################################

echo "1" >/proc/sys/net/ipv4/ip_forward


#############################################
#	  CLEAR FIREWALL RULES              #
#############################################

iptables -F
iptables -X	
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t nat -P PREROUTING ACCEPT
iptables -t mangle -P PREROUTING ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -P OUTPUT ACCEPT
iptables -t mangle -P OUTPUT ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t mangle -P POSTROUTING ACCEPT


#############################################
#        SETUP PREPROCESSING CHAINS         #
#############################################


#placeholder for future REDIRECT (dynamic)
#placeholder for future DNAT (static)


#############################################
#	    SETUP CUSTOM CHAINS             #
#############################################

iptables -N ess-acct   
iptables -N noness-acct  


#############################################
#	    SETUP INPUT CHAINS              #
#############################################

#ADVICE TAKEN FROM https://www.linuxquestions.org/questions/linux-security-4/tcp-packet-flags-syn-fin-ack-etc-and-firewall-rules-317389/

#### DEFENSE ####
#iptables -I INPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED
iptables -P INPUT DROP
iptables -A INPUT -p tcp --sport 0 -j DROP
iptables -A INPUT -p udp --sport 0 -j DROP
iptables -A INPUT -p tcp --dport 0 -j DROP
iptables -A INPUT -p udp --dport 0 -j DROP
iptables -A INPUT -p tcp --syn -m limit --limit 5/second -j ACCEPT

iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP       #DROP NEW CONNECTIONS THAT ARE NOT NEW CONNECTIONS
iptables -A INPUT -p ALL -m conntrack --ctstate INVALID -j DROP           # INVALID (NOT NEW ESTABLISHED OR RELATED
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP                      # ALL
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP              # XMAS
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP              # SYN / RST
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP              # SYN / FIN
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP                     # NULL
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP      # ALL
iptables -A INPUT -p tcp --tcp-flags ALL SYN,PSH,RST,ACK,FIN,URG -j DROP  # all 

iptables -A INPUT -p ALL -i $LOCAL_INTERFACE -j ACCEPT

#### ENABLE NETWORKING DHCP #####
iptables -A INPUT -p UDP -s 0/0 --sport 67 --dport 68 -j ACCEPT

#### SSH AND HTTP AND HTTPS ####
iptables -A INPUT -p TCP -i $WAN_INTERFACE -j ess-acct  

iptables -A ess-acct -p TCP -s 0/0 --dport 22 -j ACCEPT 
iptables -A ess-acct -p TCP -s 0/0 --sport 22 -j ACCEPT 
iptables -A ess-acct -p UDP -s 0/0 --sport 22 -j ACCEPT 
iptables -A ess-acct -p UDP -s 0/0 --sport 22 -j ACCEPT 

iptables -A ess-acct -p TCP -s 0/0 --dport 443 --sport 0:1023 -j DROP 
iptables -A ess-acct -p TCP -s 0/0 --dport 80 --sport 0:1023 -j DROP 
iptables -A ess-acct -p TCP -s 0/0 --dport 80 --sport 1024:65535 -j ACCEPT 
iptables -A ess-acct -p TCP -s 0/0 --dport 443 --sport 1024:65535 -j ACCEPT
iptables -A ess-acct -p TCP -s 0/0 --sport 443 --dport 0:1023 -j DROP 
iptables -A ess-acct -p TCP -s 0/0 --sport 80 --dport 0:1023 -j DROP 
iptables -A ess-acct -p TCP -s 0/0 --sport 80 --dport 1024:65535 -j ACCEPT 
iptables -A ess-acct -p TCP -s 0/0 --sport 443 --dport 1024:65535 -j ACCEPT 

#### CATCH ALL RELATED ACCEPT ####
iptables -A INPUT -p ALL -i $WAN_INTERFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


#############################################
#	   SETUP FORWARD CHAINS             #
#############################################

#### DEFENSE ####
iptables -I FORWARD 1 -m conntrack --ctstate ESTABLISHED,RELATED
iptables -P FORWARD DROP

iptables -A FORWARD -i $WAN_INTERFACE -m tcp -p tcp --dport 22 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m tcp -p tcp --sport 22 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m udp -p udp --dport 22 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m udp -p udp --sport 22 -j ess-acct 

iptables -A FORWARD -i $WAN_INTERFACE -m tcp -p tcp --dport 80 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m tcp -p tcp --sport 80 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m udp -p udp --dport 80 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m udp -p udp --sport 80 -j ess-acct 

iptables -A FORWARD -i $WAN_INTERFACE -m tcp -p tcp --dport 443 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m tcp -p tcp --sport 443 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m udp -p udp --dport 443 -j ess-acct 
iptables -A FORWARD -i $WAN_INTERFACE -m udp -p udp --sport 443 -j ess-acct 

iptables -A FORWARD -i $LOCAL_INTERFACE -m tcp -p tcp --dport 22 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m tcp -p tcp --sport 22 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m udp -p udp --dport 22 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m udp -p udp --sport 22 -j ess-acct 

iptables -A FORWARD -i $LOCAL_INTERFACE -m tcp -p tcp --dport 80 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m tcp -p tcp --sport 80 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m udp -p udp --dport 80 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m udp -p udp --sport 80 -j ess-acct 

iptables -A FORWARD -i $LOCAL_INTERFACE -m tcp -p tcp --dport 443 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m tcp -p tcp --sport 443 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m udp -p udp --dport 443 -j ess-acct 
iptables -A FORWARD -i $LOCAL_INTERFACE -m udp -p udp --sport 443 -j ess-acct 

iptables -A FORWARD -s 0/0 -m udp -p udp -j noness-acct 
iptables -A FORWARD -s 0/0 -m tcp -p tcp -j noness-acct 

#############################################
#	   SETUP OUTPUT CHAINS              #
#############################################

#### DEFENSE ####
iptables -P OUTPUT DROP
iptables -I OUTPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED

#### ENABLE NETWORKING ####
iptables -A OUTPUT -p ALL -s $LOCAL_ADDRESS -j ACCEPT
iptables -A OUTPUT -p ALL -o $LOCAL_INTERFACE -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 68 -m conntrack --ctstate NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

iptables -A OUTPUT -p tcp --dport 22 -d 0/0 -j ess-acct  
iptables -A OUTPUT -p tcp --sport 22 -d 0/0 -j ess-acct  
iptables -A OUTPUT -p tcp --dport 80 -d 0/0 -j ess-acct  
iptables -A OUTPUT -p tcp --sport 80 -d 0/0 -j ess-acct  
iptables -A OUTPUT -p tcp --dport 443 -d 0/0 -j ess-acct  
iptables -A OUTPUT -p tcp --sport 443 -d 0/0 -j ess-acct  

#### NONESSENTIAL ####
iptables -A noness-acct -p tcp ! --sport 0 -j ACCEPT  
iptables -A noness-acct -p tcp ! --dport 0 -j ACCEPT  

#############################################
#        SETUP POSTPROCESSING CHAINS        #
#############################################


#placeholder for future MASQUERADE (dynamic)
#placeholder for future SNAT (static)


#############################################
#	  ENABLE CUSTOM TESTING             #
#############################################

if [  "$1" = "testing"  ]
then
	echo "ENABLING ALL ICMP MESSAGING."
	iptables -A INPUT -i $WAN_INTERFACE -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
	iptables -A INPUT -i $WAN_INTERFACE -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT  

	iptables -A OUTPUT -m icmp -p icmp --icmp-type echo-request -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type echo-request -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type echo-reply -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type echo-reply -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type source-quench -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type source-quench -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type echo-request -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type echo-request -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type destination-unreachable -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type destination-unreachable -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type network-unreachable -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type network-unreachable -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type host-unreachable -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type host-unreachable -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type protocol-unreachable -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type protocol-unreachable -j ACCEPT

	iptables -A OUTPUT -m icmp -p icmp --icmp-type port-unreachable -j ACCEPT
	iptables -A INPUT -m icmp -p icmp --icmp-type port-unreachable -j ACCEPT
fi

#############################################
exit 0

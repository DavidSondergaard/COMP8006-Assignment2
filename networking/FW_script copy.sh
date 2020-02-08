#!/bin/bash

####################################################################
#                                                                  #
#  Purpose:  To setup the firewall on the firewall computer.       #
#                                                                  #
####################################################################

#############################################
#	USER DEFINED VARIABLES              #
#############################################

##### TOOLS ####
ITBL="/sbin/iptables"
IFC="/sbin/ifconfig"
RTE="/sbin/route"
IP="/sbin/ip"
TEE="/bin/tee"
ECHO="/bin/echo"

##### NETWORK INTERFACES ####
#Outside Interface
WAN_INTERFACE="enp0s20f0u2"
WAN_ADDRESS="192.168.1.130"
WAN_CHANGE_IP=1

#Computer Interface
LOCAL_INTERFACE="lo"
LOCAL_ADDRESS="127.0.0.1"

#Internal LAN Interface
LAN_INTERFACE="enp0s20f0u3u3"
LAN_ADDRESS="192.168.10.2"
LAN_CHANGE_IP=1

#Allowed Services (NOTE:  44-252 not included here)
ALLOWED_TCP="80 443"
ALLOWED_UDP="80 443"
ALLOWED_ICMP="0 1:3 5 7:14 19 40 42 43 20:29 41 253:255 4 6 15:18 30:38"
#ALLOWED_ICMP="0 1:3 5 7:14 19 40 42 43 20:29 41 253:255 4 6 15:18 30:38"

#Blocked Services
BLOCKED_TCP=""
BLOCKED_UDP=""
BLOCKED_ICMP=""

#External Blocked Services    
EXTERNAL_INBOUND_BLOCKED_UDP_PORTS="32768:32775 137:139"
EXTERNAL_INBOUND_BLOCKED_TCP_PORTS="32768:32775 137:139 111 115"

#############################################
#############################################
######                                 ######
######    DO NOT EDIT BELOW THIS BOX   ######
######                                 ######
#############################################
#############################################

#CRITICAL SERVICES
ALLOWED_ALWAYS_TCP="53 67 68"
ALLOWED_ALWAYS_UDP="53 67 68"
ALLOWED_ALWAYS_ICMP=""

BLOCKED_ALWAYS_TCP="23"
BLOCKED_ALWAYS_UDP="23"
BLOCKED_ALWAYS_ICMP="23"


#############################################
#           CUSTOMIZE INTERFACES            #
#############################################


#############################################
#      SYSTEM SETUP FOR FORWARDING          #
#############################################

$ECHO "1" >/proc/sys/net/ipv4/ip_forward
$ECHO "1" | $TEE /proc/sys/net/ipv4/ip_forward

#############################################
#	  CLEAR FIREWALL RULES              #
#############################################

$ITBL -F
$ITBL -X	
$ITBL -t nat -F
$ITBL -t nat -X
$ITBL -t mangle -F
$ITBL -t mangle -X
$ITBL -t nat -P PREROUTING ACCEPT
$ITBL -t mangle -P PREROUTING ACCEPT
$ITBL -P INPUT ACCEPT
$ITBL -P FORWARD ACCEPT
$ITBL -P OUTPUT ACCEPT
$ITBL -t nat -P OUTPUT ACCEPT
$ITBL -t mangle -P OUTPUT ACCEPT
$ITBL -t nat -P POSTROUTING ACCEPT
$ITBL -t mangle -P POSTROUTING ACCEPT

#if [ $1 == "clear" ];
#then
#	exit;
#fi

#############################################
#        SETUP PREPROCESSING CHAINS         #
#############################################


#placeholder for future REDIRECT (dynamic)
#placeholder for future DNAT (static)


#############################################
#	    SETUP CUSTOM CHAINS             #
#############################################
$ITBL -N allowed_tcp
$ITBL -N allowed_udp
$ITBL -N allowed_icmp
$ITBL -N blocked_tcp
$ITBL -N blocked_udp
$ITBL -N blocked_icmp
$ITBL -N blocked_inbound_firewall
$ITBL -N malicious_bytes
$ITBL -N allowed_fragments



#############################################
#        SETUP POSTPROCESSING CHAINS        #
#############################################




$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p tcp -m tcp --dport 20 -j TOS --set-tos Maximize-Throughput
$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p tcp -m tcp --sport 20 -j TOS --set-tos Maximize-Throughput
$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p udp -m udp --dport 20 -j TOS --set-tos Maximize-Throughput
$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p udp -m udp --sport 20 -j TOS --set-tos Maximize-Throughput

FTPSSH="20 21 22"
for x in $FTPSSH
do 
	$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p tcp -m tcp --dport $x -j TOS --set-tos Minimize-Delay
	$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p tcp -m tcp --sport $x -j TOS --set-tos Minimize-Delay
	$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p udp -m udp --dport $x -j TOS --set-tos Minimize-Delay
	$ITBL -t mangle -A PREROUTING -i $WAN_INTERFACE -p udp -m udp --sport $x -j TOS --set-tos Minimize-Delay
done


#############################################
#	    SETUP INPUT CHAINS              #
#############################################

#ADVICE TAKEN FROM https://www.linuxquestions.org/questions/linux-security-4/tcp-packet-flags-syn-fin-ack-etc-and-firewall-rules-317389/

#### DEFENSE ####
#$ITBL -I INPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED
$ITBL -P INPUT DROP 
$ITBL -A INPUT -i $WAN_INTERFACE -p ALL -m limit --limit 1/second -j blocked_inbound_firewall
$ITBL -A INPUT -p ALL -i $LOCAL_INTERFACE -j ACCEPT
echo "TESTING A"

if [ ! -z "$ALLOWED_ALWAYS_TCP" ]
	then
		for x in $ALLOWED_ALWAYS_TCP
		do 
			$ITBL -A INPUT -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
		done
fi

if [ ! -z "$ALLOWED_ALWAYS_UDP" ]
then
for x in $ALLOWED_ALWAYS_UDP
do 
	$ITBL -A INPUT -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
done
fi

if [ ! -z "$ALLOWED_ALWAYS_ICMP" ]
then
echo "TESTING B"
for x in $ALLOWED_ALWAYS_ICMP
do 
	$ITBL -A INPUT -p all --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
done
fi

			######$ITBL -A INPUT -p tcp --sport 0 -j malicious_bytes
			#####$ITBL -A INPUT -p udp --sport 0 -j malicious_bytes
			#####$ITBL -A INPUT -p tcp --dport 0 -j malicious_bytes
			####$ITBL -A INPUT -p udp --dport 0 -j malicious_bytes
			#$ITBL -A FORWARD -p tcp --syn -m limit --limit 5/second -j ACCEPT
echo "TESTING B1"
			$ITBL -A INPUT -i $WAN_INTERFACE -p tcp --dport 1024:65535 --syn -m conntrack --ctstate NEW -j malicious_bytes       #DROP NEW CONNECTIONS THAT ARE NOT NEW CONNECTIONS
			#$ITBL -A INPUT -i $WAN_INTERFACE -p udp --dport 1024:65535 --syn -m conntrack --ctstate NEW -j malicious_bytes       #DROP NEW CONNECTIONS THAT ARE NOT NEW CONNECTIONS
			#$ITBL -A INPUT -i $WAN_INTERFACE -p all --dport 1:65535 --syn INVALID -j malicious_bytes      # INVALID (NOT NEW ESTABLISHED OR RELATED
			$ITBL -A INPUT -i $WAN_INTERFACE  -p tcp --tcp-flags ALL ALL -j malicious_bytes                      # ALL
echo "TESTING B2"
			$ITBL -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j malicious_bytes              # XMAS
			$ITBL -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j malicious_bytes              # SYN / RST
			$ITBL -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j malicious_bytes              # SYN / FIN
			$ITBL -A INPUT -p tcp --tcp-flags ALL NONE -j malicious_bytes                     # NULL
echo "TESTING B3"
			$ITBL -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j malicious_bytes      # ALL
			$ITBL -A INPUT -p tcp --tcp-flags ALL SYN,PSH,RST,ACK,FIN,URG -j malicious_bytes  # all 
			$ITBL -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j malicious_bytes #smurf
			$ITBL -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j malicious_bytes #smurf
echo "TESTING B4"
			$ITBL -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j malicious_bytes          # NULL
			$ITBL -A INPUT -p icmp --icmp-type echo-request -m limit --limit 3/s -m length --length 60:65535 #ping of death
			$ITBL -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2  #ping of death
echo "TESTING c"

#############################################
#	   SETUP FORWARD CHAINS             #
#############################################
#### DEFENSE ####
$ITBL -I FORWARD 1 -m conntrack --ctstate ESTABLISHED,RELATED
$ITBL -P FORWARD DROP
$ITBL -A FORWARD -i $WAN_INTERFACE -s 192.168.10.0/24 -m conntrack --ctstate NEW -j malicious_bytes  ##prevent external faking internal


#?|?|?|??|?|?|??|?|?|??|?|?|??|?|?|??|?|?|??|?|?|??|?|?|??|?|?|??|?|?|??|?|?|?
echo "TESTING d"
			#####$ITBL -A FORWARD -p tcp --sport 0 -j malicious_bytes
			#####$ITBL -A FORWARD -p udp --sport 0 -j malicious_bytes
			#####$ITBL -A FORWARD -p tcp --dport 0 -j malicious_bytes
			#####$ITBL -A FORWARD -p udp --dport 0 -j malicious_bytes
			#$ITBL -A FORWARD -p tcp --syn -m limit --limit 5/second -j ACCEPT
echo "TESTING B1"
			$ITBL -A FORWARD -i $WAN_INTERFACE -p tcp --dport 1024:65535 --syn -m conntrack --ctstate NEW -j malicious_bytes       #DROP NEW CONNECTIONS THAT ARE NOT NEW CONNECTIONS
			#$ITBL -A FORWARD -i $WAN_INTERFACE -p udp --dport 1024:65535 --syn -m conntrack --ctstate NEW -j malicious_bytes       #DROP NEW CONNECTIONS THAT ARE NOT NEW CONNECTIONS
			#$ITBL -A FORWARD -i $WAN_INTERFACE -p all --dport 1:65535 --syn INVALID -j malicious_bytes      # INVALID (NOT NEW ESTABLISHED OR RELATED
			$ITBL -A FORWARD -p tcp --tcp-flags ALL ALL -j malicious_bytes                      # ALL
echo "TESTING B2"
			$ITBL -A FORWARD -p tcp --tcp-flags ALL FIN,URG,PSH -j malicious_bytes              # XMAS
			$ITBL -A FORWARD -p tcp --tcp-flags SYN,RST SYN,RST -j malicious_bytes              # SYN / RST
			$ITBL -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j malicious_bytes              # SYN / FIN
			$ITBL -A FORWARD -p tcp --tcp-flags ALL NONE -j malicious_bytes                     # NULL
echo "TESTING B3"
			$ITBL -A FORWARD -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j malicious_bytes      # ALL
			$ITBL -A FORWARD -p tcp --tcp-flags ALL SYN,PSH,RST,ACK,FIN,URG -j malicious_bytes  # all 
			$ITBL -A FORWARD -p icmp -m icmp --icmp-type address-mask-request -j malicious_bytes #smurf
			$ITBL -A FORWARD -p icmp -m icmp --icmp-type timestamp-request -j malicious_bytes #smurf
echo "TESTING B4"
			$ITBL -A FORWARD -p icmp -m icmp --icmp-type timestamp-request -j malicious_bytes          # NULL
			$ITBL -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 3/s -m length --length 60:65535 #ping of death
			$ITBL -A FORWARD -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2  #ping of death
echo "TESTING c3"

#?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|?|

######


if [ ! -z "$BLOCKED_ALWAYS_TCP" ]
then
	echo "TESTING f"
	for x in $BLOCKED_ALWAYS_TCP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_tcp
	done
fi

if [ ! -z "$BLOCKED_ALWAYS_UDP" ]
then
	for x in $BLOCKED_ALWAYS_UDP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_udp
	done
fi

if [ ! -z "$BLOCKED_ALWAYS_ICMP" ]
then
	for x in $BLOCKED_ALWAYS_ICMP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_icmp
	done
fi
if [ ! -z "$ALLOWED_TCP" ]
then
	echo "TESTING g"
	for x in $ALLOWED_TCP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
	done
fi

if [ ! -z "$ALLOWED_UDP" ]
then
	for x in $ALLOWED_UDP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p udp -m udp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
	done
fi

if [ ! -z "$ALLOWED_ICMP" ]
then
	for x in $ALLOWED_ICMP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
	done
fi
	#####
	echo "TESTING h"
if [ ! -z "$BLOCKED_TCP" ]
then
	for x in $BLOCKED_TCP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_tcp
	done
fi

if [ ! -z "$BLOCKED_UDP" ]
then
	for x in $BLOCKED_UDP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_udp
	done
fi

if [ ! -z "$BLOCKED_ICMP" ]
then
	for x in $BLOCKED_ICMP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_icmp
	done
fi
	#####
	echo "TESTING i"

if [ ! -z "$ALLOWED_ALWAYS_TCP" ]
then
	for x in $ALLOWED_ALWAYS_TCP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
	done
fi

if [ ! -z "$ALLOWED_ALWAYS_UDP" ]
then
	for x in $ALLOWED_ALWAYS_UDP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
	done
fi

if [ ! -z "$ALLOWED_ALWAYS_ICMP" ]
then
	for x in $ALLOWED_ALWAYS_ICMP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
	done
fi
	######
	echo "TESTING j"

if [ ! -z "$BLOCKED_ALWAYS_TCP" ]
then
	for x in $BLOCKED_ALWAYS_TCP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_tcp
	done
fi

if [ ! -z "$BLOCKED_ALWAYS_UDP" ]
then
	for x in $BLOCKED_ALWAYS_UDP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_udp
	done
fi

if [ ! -z "$BLOCKED_ALWAYS_ICMP" ]
then
	for x in $BLOCKED_ALWAYS_ICMP
	do 
		$ITBL -A FORWARD -i $LAN_INTERFACE -o $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_icmp
	done
fi
	echo "TESTING k"
	#///////////////////////////////////////////////////////////////////////////////////////

if [ ! -z "$EXTERNAL_INBOUND_BLOCKED_UDP_PORTS" ]
then
	for x in $EXTERNAL_INBOUND_BLOCKED_UDP_PORTS
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j blocked_tcp
	done
fi

if [ ! -z "$EXTERNAL_INBOUND_BLOCKED_TCP_PORTS" ]
then
	for x in $EXTERNAL_INBOUND_BLOCKED_TCP_PORTS
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j blocked_tcp
	done
fi

if [ ! -z "$ALLOWED_TCP" ]
then
	for x in $ALLOWED_TCP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
	done
fi

if [ ! -z "$ALLOWED_UDP" ]
then
	for x in $ALLOWED_UDP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
	done
fi

if [ ! -z "$ALLOWED_ICMP" ]
then
	for x in $ALLOWED_ICMP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
	done
fi
	#####
	echo "TESTING l"

if [ ! -z "$BLOCKED_TCP" ]
then
	for x in $BLOCKED_TCP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_tcp
	done
fi

if [ ! -z "$BLOCKED_UDP" ]
then
	for x in $BLOCKED_UDP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p udp -m udp  --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_udp
	done
fi

if [ ! -z "$BLOCKED_ICMP" ]
then
	for x in $BLOCKED_ICMP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_icmp
	done
fi
	#####
	echo "TESTING m"


if [ ! -z "$ALLOWED_ALWAYS_TCP" ]
then
	for x in $ALLOWED_ALWAYS_TCP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p tcp -m tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
	done
fi

if [ ! -z "$ALLOWED_ALWAYS_UDP" ]
then
	for x in $ALLOWED_ALWAYS_UDP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p udp -m udp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
	done
fi

if [ ! -z "$ALLOWED_ALWAYS_ICMP" ]
then
	for x in $ALLOWED_ALWAYS_ICMP
	do 
		$ITBL -A FORWARD -i $WAN_INTERFACE -o $LAN_INTERFACE -p all --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
	done
fi
echo "TESTING n"
#######


$ITBL -A FORWARD -f -j allowed_fragments



#############################################
#	   SETUP OUTPUT CHAINS              #
#############################################
echo "TESTING o"
#### DEFENSE ####
$ITBL -P OUTPUT DROP
$ITBL -I OUTPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED

#### ENABLE NETWORKING ####
$ITBL -A OUTPUT -p ALL -s $LOCAL_ADDRESS -j ACCEPT
$ITBL -A OUTPUT -p ALL -o $LOCAL_INTERFACE -j ACCEPT

# if [ ! -z "$ALLOWED_TCP" ]
# then
# 	for x in $ALLOWED_TCP
# 	do 
# 		$ITBL -A OUTPUT -o LOCAL_INTERFACE -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
# 	done
# fi

# if [ ! -z "$ALLOWED_UDP" ]
# then
# 	for x in $ALLOWED_UDP
# 	do 
# 		$ITBL -A OUTPUT -p udp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
# 	done
# fi
# if [ ! -z "$ALLOWED_ICMP" ]
# then
# 	for x in $ALLOWED_ICMP
# 	do 
# 		$ITBL -A OUTPUT -p all --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
# 	done
# fi
# 	#####
# 	echo "TESTING p"

# if [ ! -z "$BLOCKED_TCP" ]
# then
# 	for x in $BLOCKED_TCP
# 	do 
# 		$ITBL -A OUTPUT -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_tcp
# 	done
# fi

# if [ ! -z "$BLOCKED_UDP" ]
# then
# 	for x in $BLOCKED_UDP
# 	do 
# 		$ITBL -A OUTPUT -p udp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_udp
# 	done
# fi

# if [ ! -z "$BLOCKED_ICMP" ]
# then
# 	for x in $BLOCKED_ICMP
# 	do 
# 		$ITBL -A OUTPUT -p udp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_icmp
# 	done
# 	#####
# 	echo "TESTING q"
# fi

# if [ ! -z "$ALLOWED_ALWAYS_TCP" ]
# then
# 	for x in $ALLOWED_ALWAYS_TCP
# 	do 
# 		$ITBL -A OUTPUT --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_tcp
# 	done
# fi

# if [ ! -z "$ALLOWED_ALWAYS_UDP" ]
# then
# 	for x in $ALLOWED_ALWAYS_UDP
# 	do 
# 		$ITBL -A OUTPUT --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_udp
# 	done
# fi

# if [ ! -z "$ALLOWED_ALWAYS_ICMP" ]
# then
# 	for x in $ALLOWED_ALWAYS_ICMP
# 	do 
# 		$ITBL -A OUTPUT --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j allowed_icmp
# 	done
# 	######
# 	echo "TESTING r"
# 	echo "TESTING ra"
# fi

# if [ ! -z "$BLOCKED_ALWAYS_TCP" ]
# then
# 	for x in $BLOCKED_ALWAYS_TCP
# 	do 
# 		$ITBL -A OUTPUT -p tcp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_tcp
# 	done
# fi

# if [ ! -z "$BLOCKED_ALWAYS_UDP" ]
# then
# 	echo "TESTING rb"
# 	for x in $BLOCKED_ALWAYS_UDP
# 	do 
# 		$ITBL -A OUTPUT -p udp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_udp
# 	done
# fi
# 	echo "TESTING rc"
# if [ ! -z "$BLOCKED_ALWAYS_ICMP" ]
# then
# 	for x in $BLOCKED_ALWAYS_ICMP
# 	do 
# 		$ITBL -A OUTPUT -p icmp --dport $x -m conntrack --ctstate NEW,ESTABLISHED -j blocked_icmp
# 	done
# fi
echo "TESTING rd"

echo "TESTING s"
#############################################
#        SETUP POSTPROCESSING CHAINS        #
#############################################


$ITBL -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE


#############################################
#        SETUP POSTPROCESSING CHAINS        #
#############################################

$ITBL -A allowed_tcp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$ITBL -A allowed_fragments -m conntrack --ctstate NEW,RELATED,ESTABLISHED -j ACCEPT
$ITBL -A allowed_udp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$ITBL -A allowed_icmp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
$ITBL -A blocked_tcp -m conntrack --ctstate NEW,ESTABLISHED -j DROP
$ITBL -A blocked_udp -m conntrack --ctstate NEW,ESTABLISHED -j DROP
$ITBL -A blocked_icmp -m conntrack --ctstate NEW,ESTABLISHED -j DROP
$ITBL -A malicious_bytes -m conntrack --ctstate NEW,ESTABLISHED -j DROP
$ITBL -A blocked_inbound_firewall -m conntrack --ctstate NEW,ESTABLISHED -j DROP
echo "TESTING t"

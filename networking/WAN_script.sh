#!/bin/bash


cat > /etc/resolv.conf << EOF

nameserver 192.168.10.1
options edns0

EOF


ip route flush dev enp60s0
ifconfig enp60s0 192.168.10.2 up
ip route add 192.168.10.1 dev enp60s0
ip route add default via 192.168.10.1
ip route add 192.168.10.0/24 via 192.168.10.1 dev enp60s0
route add 192.168.10.0/24 via 192.168.10.1 dev enp60s0

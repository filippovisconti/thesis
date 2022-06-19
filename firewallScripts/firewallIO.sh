#!/bin/bash
echo "Firewall IO rules..."

Ibytewise=ens192
Iexternal=ens160
STRONGSWAN_INTERFACE=ens160

## DNS client 
iptables -A OUTPUT -p udp --dport 53  -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p udp --sport 53  -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

## DNS server per IPSec
iptables -A OUTPUT -p udp --sport 53  -o $STRONGSWAN_INTERFACE -j ACCEPT
iptables -A INPUT  -p udp --dport 53  -i $STRONGSWAN_INTERFACE -j ACCEPT

# DHCP Server per IPSec
iptables -A OUTPUT -p udp --sport 67  -o $STRONGSWAN_INTERFACE -j ACCEPT
iptables -A INPUT  -p udp --dport 67  -i $STRONGSWAN_INTERFACE -j ACCEPT

# HTTP client
iptables -A INPUT  -p tcp --sport 80  -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80  -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A INPUT  -p tcp --sport 443 -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# NTP client
iptables -A INPUT  -p udp --sport 123 -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p udp --dport 123 -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT


# iperf3 server TCP
iptables -A INPUT  -p tcp --dport 9999 -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 9999 -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# iperf3 server UDP
iptables -A INPUT  -p udp --dport 9999 -i $Iexternal -j ACCEPT
iptables -A OUTPUT -p udp --sport 9999 -o $Iexternal -j ACCEPT

# iptables -A INPUT  -p tcp --sport 8080  -i lo -j ACCEPT
# iptables -A OUTPUT -p tcp --dport 8080  -o lo -j ACCEPT
# iptables -A INPUT  -p tcp --sport 6060  -i lo -j ACCEPT
# iptables -A OUTPUT -p tcp --dport 6060  -o lo -j ACCEPT

# iptables -A INPUT  -p tcp --dport 8080  -i lo -j ACCEPT
# iptables -A OUTPUT -p tcp --sport 8080  -o lo -j ACCEPT
# iptables -A INPUT  -p tcp --dport 6060  -i lo -j ACCEPT
# iptables -A OUTPUT -p tcp --sport 6060  -o lo -j ACCEPT
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# per IPSec
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT

iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT


# ICMP on every interface
iptables -A INPUT  -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

echo "Done."

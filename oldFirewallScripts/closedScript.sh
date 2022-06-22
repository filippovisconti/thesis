#!/bin/bash

#---------- FLUSH FIREWALL ----------#
/root/firewallScripts/flush_firewall.sh

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

Ibytewise=ens192
Iinternal=ens224
Iexternal=ens160

#----------- SSH --------------------#
iptables -A INPUT  -p tcp --dport 65022 -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 65022 -o $Iexternal -m state --state ESTABLISHED     -j ACCEPT

iptables -A INPUT  -p tcp --dport 65022 -i $Ibytewise -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p tcp --sport 65022 -o $Ibytewise -m state --state ESTABLISHED     -j ACCEPT 

#----------- I/0 FILE ---------------#
/root/firewallScripts/firewallIO.sh

service iptables save

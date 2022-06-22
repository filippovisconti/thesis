#!/bin/bash
echo "Starting script."
#---------- FLUSH FIREWALL ----------#
/root/firewallScripts/flush_firewall.sh
echo "Flushed old rules."
#---------- Enable routing ----------#
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "Enabled forwarding."

#---------- Variables ---------------#
Iinternal=ens224
Iexternal=ens160
STRONGSWAN_INTERFACE=ens160
WG_INTERFACE=wg0
OPENVPN_INTERFACE=tun0

EXT=0/0
DMZLAN=50.50.50.0/24
SSLAN=10.0.2.0/24
WGLAN=10.66.66.0/24
OVLAN=10.8.0.0/24

FWexternalIP=10.222.111.2
FWDMZIP=50.50.50.1
DMZCLIENT=50.50.50.3

# Chain creation
iptables -N de # -- DMZ -> EXT
iptables -N ed

iptables -N dw # -- DMZ -> WG
iptables -N wd

iptables -N ds # -- DMZ -> SS
iptables -N sd

iptables -N dop # -- DMZ -> OVPN
iptables -N opd
echo "Created chains."


#---SETTING POLICIES---#
iptables  -P INPUT   DROP
iptables  -P OUTPUT  DROP
iptables  -P FORWARD DROP

ip6tables -P INPUT   DROP
ip6tables -P OUTPUT  DROP
ip6tables -P FORWARD DROP

echo "Set default policies."


# Enabling destination network address translation to expose webserver
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 64022 -j DNAT --to $DMZCLIENT:22
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 80    -j DNAT --to $DMZCLIENT:80
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 443   -j DNAT --to $DMZCLIENT:443
iptables -t nat -A PREROUTING -i $Iexternal -s $EXT -d $FWexternalIP -p tcp --dport 64999 -j DNAT --to $DMZCLIENT:5201 # iperf3
echo "Prerouting done."


echo "EXT -> DMZ"
iptables -A FORWARD -i $Iexternal            -o $Iinternal              -s $EXT    -d $DMZLAN -j ed
iptables -A FORWARD -i $Iinternal            -o $Iexternal              -s $DMZLAN -d $EXT    -j de

echo "SS -> DMZ"
iptables -A FORWARD -i $STRONGSWAN_INTERFACE -o $Iinternal              -s $SSLAN  -d $DMZLAN -j sd
iptables -A FORWARD -i $Iinternal            -o $STRONGSWAN_INTERFACE   -s $DMZLAN -d $SSLAN  -j ds

echo "WG -> DMZ"
iptables -A FORWARD -i $WG_INTERFACE         -o $Iinternal              -s $WGLAN  -d $DMZLAN -j wd
iptables -A FORWARD -i $Iinternal            -o $WG_INTERFACE           -s $DMZLAN -d $WGLAN  -j dw

echo "OVPN -> DMZ"
iptables -A FORWARD -i $OPENVPN_INTERFACE    -o $Iinternal              -s $OVLAN  -d $DMZLAN -j opd
iptables -A FORWARD -i $Iinternal            -o $OPENVPN_INTERFACE      -s $DMZLAN -d $OVLAN  -j dop

# IPSec
iptables -A FORWARD -s $SSLAN -m policy --dir in  --pol ipsec --proto esp -j ACCEPT
iptables -A FORWARD -d $SSLAN -m policy --dir out --pol ipsec --proto esp -j ACCEPT
iptables -A FORWARD -i ens160 -o wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -j ACCEPT 

#----------- SSH --------------------#
echo "SSH..."
iptables -A INPUT  -p tcp --dport 65022 -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 65022 -o $Iexternal -m state --state ESTABLISHED     -j ACCEPT

iptables -A INPUT  -p tcp --dport 65022 -i ens192     -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p tcp --sport 65022 -o ens192     -m state --state ESTABLISHED     -j ACCEPT 
echo "SSH... Done."

#----------- FORWARD FILE -----------#
echo "Internet and DMZ..."
# Forward DNS to Internet from DMZ
iptables -A de -p udp --dport 53  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p udp --sport 53  -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTP to Internet from LAN
iptables -A de -p tcp --dport 80  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p tcp --sport 80  -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTPS to Internet from LAN
iptables -A de -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p tcp --sport 443 -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTP server from Internet to DMZ
iptables -A ed -p tcp --dport 80  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 80  -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTPS server from Internet to DMZ
iptables -A ed -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 443 -m state --state ESTABLISHED     -j ACCEPT
echo "Internet and DMZ... Done."

echo "VPN..."

# Forward SSH from Internet to DMZ
iptables -A ed  -p tcp --dport 22   -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de  -p tcp --sport 22   -m state --state ESTABLISHED     -j ACCEPT

# Forward iperf3 TCP from Internet to DMZ
iptables -A ed  -p tcp --dport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de  -p tcp --sport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
# iperf3 UDP
iptables -A ed  -p udp --dport 5201 -j ACCEPT
iptables -A de  -p udp --sport 5201 -j ACCEPT

# Forward iperf3 TCP from OpenVPN to DMZ
iptables -A opd -p tcp --dport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dop -p tcp --sport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
# iperf3 UDP
iptables -A opd -p udp --dport 5201 -j ACCEPT
iptables -A dop -p udp --sport 5201 -j ACCEPT

# Forward iperf3 TCP from IPSec to DMZ
iptables -A sd  -p tcp --dport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ds  -p tcp --sport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
# iperf3 UDP
iptables -A sd  -p udp --dport 5201 -j ACCEPT
iptables -A ds  -p udp --sport 5201 -j ACCEPT

# Forward iperf3 TCP from WireGuardVPN to DMZ
iptables -A wd  -p tcp --dport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dw  -p tcp --sport 5201 -m state --state NEW,ESTABLISHED -j ACCEPT
# iperf3 UDP
iptables -A wd  -p udp --dport 5201 -j ACCEPT
iptables -A dw  -p udp --sport 5201 -j ACCEPT
#TEMPORARY
iptables -A wd  -p tcp --dport 22   -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A dw  -p tcp --sport 22   -m state --state NEW,ESTABLISHED -j ACCEPT

echo "VPN... Done."

# NTP client
iptables -A de  -p udp --dport 123  -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed  -p udp --sport 123  -m state --state ESTABLISHED     -j ACCEPT

iptables -A sd  -p icmp  -j ACCEPT
iptables -A ds  -p icmp  -j ACCEPT

iptables -A wd  -p icmp  -j ACCEPT
iptables -A dw  -p icmp  -j ACCEPT

iptables -A opd -p icmp  -j ACCEPT
iptables -A dop -p icmp  -j ACCEPT

#----------- I/0 FILE ---------------#
echo "IO..."
## DNS client 
iptables -A OUTPUT -p udp --dport 53   -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p udp --sport 53   -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

## DNS server per IPSec
iptables -A OUTPUT -p udp --sport 53   -o $STRONGSWAN_INTERFACE                       -j ACCEPT
iptables -A INPUT  -p udp --dport 53   -i $STRONGSWAN_INTERFACE                       -j ACCEPT

# DHCP Server per IPSec
iptables -A OUTPUT -p udp --sport 67   -o $STRONGSWAN_INTERFACE                       -j ACCEPT
iptables -A INPUT  -p udp --dport 67   -i $STRONGSWAN_INTERFACE                       -j ACCEPT

# HTTP client
iptables -A INPUT  -p tcp --sport 80   -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80   -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# HTTPS client
iptables -A INPUT  -p tcp --sport 443  -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443  -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# NTP client
iptables -A INPUT  -p udp --sport 123  -i $Iexternal -m state --state ESTABLISHED     -j ACCEPT
iptables -A OUTPUT -p udp --dport 123  -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# OpenVPN server
iptables -A INPUT  -p tcp --dport 1194 -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 1194 -o $Iexternal -m state --state ESTABLISHED     -j ACCEPT

# iperf3 client TCP
iptables -A OUTPUT -p tcp --dport 5201 -o $Iinternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT  -p tcp --sport 5201 -i $Iinternal -m state --state NEW,ESTABLISHED -j ACCEPT

# iperf3 client UDP
iptables -A OUTPUT -p udp --dport 5201 -o $Iinternal                                  -j ACCEPT
iptables -A INPUT  -p udp --sport 5201 -i $Iinternal                                  -j ACCEPT

# iperf3 server TCP
iptables -A INPUT  -p tcp --dport 9999 -i $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 9999 -o $Iexternal -m state --state NEW,ESTABLISHED -j ACCEPT

# iperf3 server UDP
iptables -A INPUT  -p udp --dport 9999 -i $Iexternal                                  -j ACCEPT
iptables -A OUTPUT -p udp --sport 9999 -o $Iexternal                                  -j ACCEPT

# per IPSec
iptables -A INPUT  -p udp --dport 500                                                 -j ACCEPT
iptables -A INPUT  -p udp --dport 4500                                                -j ACCEPT
iptables -A INPUT  -m state --state RELATED,ESTABLISHED                               -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED                               -j ACCEPT

# Wireguard server
iptables -A INPUT  -p udp --dport 62873 -i $Iexternal                                 -j ACCEPT 
iptables -A OUTPUT -p udp --sport 62873 -o $Iexternal                                 -j ACCEPT
# ICMP on every interface
iptables -A INPUT  -p icmp                                                            -j ACCEPT
iptables -A OUTPUT -p icmp                                                            -j ACCEPT

iptables -A INPUT  -i lo                                                              -j ACCEPT
iptables -A OUTPUT -o lo                                                              -j ACCEPT
echo "IO... Done."

iptables -t nat    -A POSTROUTING -s $DMZLAN  -o $Iexternal            -j MASQUERADE
iptables -t nat    -A POSTROUTING -s $WGLAN   -o $WG_INTERFACE         -j MASQUERADE
iptables -t nat    -A POSTROUTING -s $SSLAN   -o $STRONGSWAN_INTERFACE -j MASQUERADE
iptables -t nat    -A POSTROUTING -s $SSLAN   -o $STRONGSWAN_INTERFACE -m policy --pol ipsec --dir out -j ACCEPT

iptables -t mangle -A FORWARD -m policy --pol ipsec --dir in  -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1280
iptables -t mangle -A FORWARD -m policy --pol ipsec --dir out -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1280

echo "Postrouting done."

service iptables save

echo "WG..."
systemctl restart wg-quick@wg0
sleep 1
systemctl status wg-quick@wg0 -l
echo "WG... Done."

sleep 3

echo "OVPN..."
systemctl restart openvpn-server@server
sleep 1
systemctl status openvpn-server@server -l
echo "OVPN... Done."

echo "Finished."
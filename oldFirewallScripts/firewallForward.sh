echo "Setting forwarding rules."

#iptables -I FORWARD -j NFQUEUE --queue-num=4 --queue-bypass

# ----------- ---------------- ----------- #
echo "Internet and DMZ... Done."
# Forward DNS to Internet from DMZ
iptables -A de -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p udp --sport 53 -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTP to Internet from LAN
iptables -A de -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p tcp --sport 80 -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTPS to Internet from LAN
iptables -A de -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p tcp --sport 443 -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTP server from Internet to DMZ
iptables -A ed -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 80 -m state --state ESTABLISHED     -j ACCEPT

# Forward HTTPS server from Internet to DMZ
iptables -A ed -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 443 -m state --state ESTABLISHED     -j ACCEPT

# Forward TOMCAT from Internet to DMZ
iptables -A ed -p tcp --dport 8080 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 8080 -m state --state ESTABLISHED     -j ACCEPT

# Forward TOMCAT from Internet to DMZ
iptables -A ed -p tcp --dport 8443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 8443 -m state --state ESTABLISHED     -j ACCEPT

# Forward SAMBA from Internet to DMZ
#iptables -A ed -p udp --dport 137     -j ACCEPT
#iptables -A de -p udp --sport 137     -j ACCEPT

#iptables -A ed -p udp --dport 138     -j ACCEPT
#iptables -A de -p udp --sport 138     -j ACCEPT

#iptables -A ed -p tcp --dport 139     -j ACCEPT
#iptables -A de -p tcp --sport 139     -j ACCEPT

# Forward SAMBA from Internet to DMZ
#iptables -A ed -p tcp --dport 445     -j ACCEPT
#iptables -A de -p tcp --sport 445     -j ACCEPT

iptables -A FORWARD -s 10.0.2.0/24 -m policy --dir in --pol ipsec --proto esp -j ACCEPT
iptables -A FORWARD -d 10.0.2.0/24 -m policy --dir out --pol ipsec --proto esp -j ACCEPT

# Forward SSH from Internet to DMZ
iptables -A ed -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A de -p tcp --sport 22 -m state --state ESTABLISHED     -j ACCEPT

# NTP client
iptables -A de -p udp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A ed -p udp --sport 123 -m state --state ESTABLISHED     -j ACCEPT

iptables -A ed -p icmp  -j ACCEPT
iptables -A de -p icmp  -j ACCEPT
# ----------- ---------------- ----------- #

echo "Bytewise and DMZ... Done."


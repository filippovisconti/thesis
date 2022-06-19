STRONGSWAN_INTERFACE=ens160

# iptables -N SSH_BRUTE_FORCE_MITIGATION
# iptables -A SSH_BRUTE_FORCE_MITIGATION -m recent --name SSH --set
# iptables -A SSH_BRUTE_FORCE_MITIGATION -m recent --name SSH --update --seconds 300 --hitcount 10 -m limit --limit 1/second --limit-burst 100 -j LOG --log-prefix "iptables[ssh-brute-force]: "
# iptables -A SSH_BRUTE_FORCE_MITIGATION -m recent --name SSH --update --seconds 300 --hitcount 10 -j DROP
# iptables -A SSH_BRUTE_FORCE_MITIGATION -j ACCEPT

# iptables -A INPUT -i lo -j ACCEPT
# iptables -A INPUT -p tcp --dport 22 --syn -m conntrack --ctstate NEW -j SSH_BRUTE_FORCE_MITIGATION
# iptables -A INPUT -p udp --dport 500 -j ACCEPT
# iptables -A INPUT -p udp --dport 4500 -j ACCEPT
# iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A FORWARD -s 10.0.2.0/24 -m policy --dir in --pol ipsec --proto esp -j ACCEPT
iptables -A FORWARD -d 10.0.2.0/24 -m policy --dir out --pol ipsec --proto esp -j ACCEPT

# iptables -A OUTPUT -o lo -j ACCEPT

iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT

iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 123 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.0.2.0/24 -o $STRONGSWAN_INTERFACE -m policy --pol ipsec --dir out -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.2.0/24 -o $STRONGSWAN_INTERFACE -j MASQUERADE

iptables -t mangle -A FORWARD -m policy --pol ipsec --dir in -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1280
iptables -t mangle -A FORWARD -m policy --pol ipsec --dir out -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1280

iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP

ip6tables -P FORWARD DROP
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
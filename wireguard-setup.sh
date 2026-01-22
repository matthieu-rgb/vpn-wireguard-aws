#!/bin/bash
set -e

# Variables
SERVER_IP="10.8.0.1"
CLIENT_IP="10.8.0.2"
SERVER_PORT="51820"
INTERFACE="wg0"

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation WireGuard
apt-get install -y wireguard wireguard-tools

# Activation du forwarding IP
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Génération des clés serveur
cd /etc/wireguard
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Récupération des clés
SERVER_PRIVATE_KEY=$(cat server_private.key)

# Détecter l'interface réseau principale (ens5, eth0, etc.)
NET_INTERFACE=$(ip route show default | awk '{print $5}')

# Configuration WireGuard serveur
cat > /etc/wireguard/${INTERFACE}.conf <<EOF
[Interface]
Address = ${SERVER_IP}/24, fd00:cafe::1/64
ListenPort = ${SERVER_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

PostUp = iptables -A FORWARD -i ${INTERFACE} -o ${NET_INTERFACE} -j ACCEPT; iptables -A FORWARD -i ${NET_INTERFACE} -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${NET_INTERFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${INTERFACE} -o ${NET_INTERFACE} -j ACCEPT; iptables -D FORWARD -i ${NET_INTERFACE} -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o ${NET_INTERFACE} -j MASQUERADE
PostUp = ip6tables -A FORWARD -i ${INTERFACE} -o ${NET_INTERFACE} -j ACCEPT; ip6tables -A FORWARD -i ${NET_INTERFACE} -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; ip6tables -t nat -A POSTROUTING -s fd00:cafe::/64 -o ${NET_INTERFACE} -j MASQUERADE
PostDown = ip6tables -D FORWARD -i ${INTERFACE} -o ${NET_INTERFACE} -j ACCEPT; ip6tables -D FORWARD -i ${NET_INTERFACE} -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; ip6tables -t nat -D POSTROUTING -s fd00:cafe::/64 -o ${NET_INTERFACE} -j MASQUERADE
EOF

# Permissions strictes
chmod 600 /etc/wireguard/${INTERFACE}.conf
chmod 600 /etc/wireguard/server_private.key

# Démarrage WireGuard
systemctl enable wg-quick@${INTERFACE}
systemctl start wg-quick@${INTERFACE}

# Sauvegarder les infos
cat > /root/vpn-info.txt <<EOF
=== WireGuard Server Info ===
Server Public Key: $(cat /etc/wireguard/server_public.key)
Server IP: ${SERVER_IP}
Port: ${SERVER_PORT}
Network Interface: ${NET_INTERFACE}
EOF

chmod 600 /root/vpn-info.txt
echo "WireGuard installation completed!"

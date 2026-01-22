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
SERVER_PUBLIC_KEY=$(cat server_public.key)

# Configuration WireGuard serveur
cat > /etc/wireguard/${INTERFACE}.conf <<EOF
[Interface]
Address = ${SERVER_IP}/24
ListenPort = ${SERVER_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

# Règles iptables pour le NAT
PostUp = iptables -A FORWARD -i ${INTERFACE} -o eth0 -j ACCEPT; iptables -A FORWARD -i eth0 -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i ${INTERFACE} -o eth0 -j ACCEPT; iptables -D FORWARD -i eth0 -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
PostUp = ip6tables -A FORWARD -i ${INTERFACE} -o eth0 -j ACCEPT; ip6tables -A FORWARD -i eth0 -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; ip6tables -t nat -A POSTROUTING -s fd00:cafe::/64 -o eth0 -j MASQUERADE
PostDown = ip6tables -D FORWARD -i ${INTERFACE} -o eth0 -j ACCEPT; ip6tables -D FORWARD -i eth0 -o ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT; ip6tables -t nat -D POSTROUTING -s fd00:cafe::/64 -o eth0 -j MASQUERADE
# Configuration client (sera ajoutée manuellement après)
# [Peer]
# PublicKey = CLIENT_PUBLIC_KEY
# AllowedIPs = ${CLIENT_IP}/32
EOF

# Permissions strictes
chmod 600 /etc/wireguard/${INTERFACE}.conf
chmod 600 /etc/wireguard/server_private.key

# Activation et démarrage de WireGuard
systemctl enable wg-quick@${INTERFACE}
systemctl start wg-quick@${INTERFACE}

# Sauvegarde des informations pour récupération facile
cat > /root/vpn-info.txt <<EOF
=== WireGuard VPN Server Information ===

Server Public Key: ${SERVER_PUBLIC_KEY}
Server Private Key: ${SERVER_PRIVATE_KEY}

Server IP (tunnel): ${SERVER_IP}
Client IP (tunnel): ${CLIENT_IP}
Listen Port: ${SERVER_PORT}

Configuration file: /etc/wireguard/${INTERFACE}.conf

=== Next Steps ===
1. Generate client keys on your local machine
2. Add client peer to server config
3. Create client config file

=== Useful Commands ===
- Check status: sudo wg show
- Restart: sudo systemctl restart wg-quick@${INTERFACE}
- Logs: sudo journalctl -u wg-quick@${INTERFACE} -f
EOF

chmod 600 /root/vpn-info.txt

echo "WireGuard installation completed successfully!"
echo "Server info saved to /root/vpn-info.txt"

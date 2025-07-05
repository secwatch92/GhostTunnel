#!/bin/bash
# WireGuard Installer and User Generator

source ./scripts/helpers.sh

VPN_USERS="$1"
SERVER_NAME="$2"
DNS_SERVER="$3"
INTERFACE_NAME=$(ip -o -4 route show to default | awk '{print $5}')

status "Configuring WireGuard for $VPN_USERS users on interface $INTERFACE_NAME"

# Generate server keys
umask 077
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey

# Server configuration
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE_NAME -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE_NAME -j MASQUERADE
MTU = 1280
EOF

# Create users
mkdir -p /etc/wireguard/clients
for i in $(seq 1 $VPN_USERS); do
  CLIENT_IP="10.8.0.$((i+1))"
  CLIENT_PRIVKEY=$(wg genkey)
  CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

  echo -e "\n#Client $i\n[Peer]\nPublicKey = $CLIENT_PUBKEY\nAllowedIPs = $CLIENT_IP/32" >> /etc/wireguard/wg0.conf

  cat > "/etc/wireguard/clients/client$i.conf" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP/24
DNS = $DNS_SERVER

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = $SERVER_NAME:443
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

  qrencode -t png -o "/etc/wireguard/clients/client$i.png" < "/etc/wireguard/clients/client$i.conf"
done

# Enable service
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
check_error "Failed to start WireGuard service"

status "WireGuard setup complete"

#!/bin/bash
# Main installer for the Ultimate VPN Deployment project

# --- Load Helpers and Configuration ---
source scripts/helpers.sh
source config.sh
check_error "Failed to load configuration. Make sure config.sh exists and is sourced correctly."

# === 1. Prerequisites Check ===
status "Checking prerequisites"
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with root privileges"
  exit 1
fi

UBUNTU_VER=$(lsb_release -rs)
if [[ "$UBUNTU_VER" != "22.04" && "$UBUNTU_VER" != "24.04" ]]; then
  echo "This script only supports Ubuntu 22.04 and 24.04"
  exit 1
fi

# === 2. System Preparation ===
status "Updating system and installing prerequisites"
apt update && apt upgrade -y
apt install -y wireguard wireguard-tools resolvconf jq openssl iptables-persistent \
zram-config curl git qrencode nginx certbot python3-certbot-nginx bc
check_error "Failed to install prerequisite packages."

# Disable unnecessary services
status "Disabling unnecessary services"
systemctl disable --now apparmor ufw snapd 2>/dev/null

# === 3. Get User Input ===
status "Gathering information"
read -p "Do you have a custom domain? (y/N) " USE_DOMAIN
if [[ $USE_DOMAIN =~ ^[Yy]$ ]]; then
  read -p "Enter your domain name: " DOMAIN_NAME
  read -p "Email address for SSL certificate (for Let's Encrypt notices): " EMAIL
  SERVER_NAME="$DOMAIN_NAME"
else
  SERVER_NAME=$(curl -s ifconfig.me)
  DOMAIN_NAME=""
  EMAIL=""
fi

# === 4. Execute Setup Modules ===
status "Starting modular setup..."
./scripts/setup_firewall.sh
./scripts/setup_cloak.sh "$CLOAK_REDIR"
./scripts/setup_wireguard.sh "$VPN_USERS" "$SERVER_NAME" "$DNS_SERVER"
./scripts/setup_nginx_and_ssl.sh "$SERVER_NAME" "$DOMAIN_NAME" "$EMAIL"
./scripts/setup_monitoring.sh "$PATH_ROTATION_INTERVAL"

# === 5. Deployment Complete ===
status "Deployment completed successfully!"
echo "================================================"
echo " VPN Server Information"
echo "================================================"
echo "- Connection address: $SERVER_NAME"
echo "- Cloak port: 443"
echo "- Current VPN path: $(cat /var/www/html/current-path 2>/dev/null || echo 'N/A')"
echo ""
echo "=== Client Information ==="
echo "Config files are located in: /etc/wireguard/clients/"
echo "QR Codes (PNG files) are in: /etc/wireguard/clients/"
echo ""
echo "=== Management Commands ==="
echo "Rotate VPN path: sudo /usr/local/bin/rotate-path.sh"
echo "Check status: systemctl status cloak wg-quick@wg0 nginx"
echo "View monitor logs: tail -f /var/log/vpn-monitor.log"
echo "================================================"

exit 0

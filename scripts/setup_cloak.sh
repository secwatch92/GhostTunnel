#!/bin/bash
# Cloak Installer and Configurator

source ./scripts/helpers.sh

CLOAK_REDIR="$1"

status "Installing and configuring Cloak"

# Get latest Cloak version
CLOAK_VER=$(curl -s "https://api.github.com/repos/cbeuw/Cloak/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
wget -q "https://github.com/cbeuw/Cloak/releases/download/$CLOAK_VER/ck-server-linux-amd64" -O /usr/local/bin/ck-server
chmod +x /usr/local/bin/ck-server
check_error "Failed to download or install Cloak binary"

# Generate keys and config
mkdir -p /etc/cloak
ck-server -key > /etc/cloak/keys.json
check_error "Failed to generate Cloak keys"

jq -n --arg pk "$(jq -r '.PrivateKey' /etc/cloak/keys.json)" \
--arg redir "$CLOAK_REDIR" \
'{
  "ProxyBook": {
    "wg": ["udp", "127.0.0.1:51820"]
  },
  "BindAddr": [":443"],
  "RedirAddr": $redir,
  "PrivateKey": $pk,
  "StreamTimeout": 300
}' > /etc/cloak/config.json

# Systemd service for Cloak
cat > /etc/systemd/system/cloak.service <<EOF
[Unit]
Description=Cloak Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ck-server -c /etc/cloak/config.json
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cloak
systemctl start cloak
check_error "Failed to start Cloak service"

status "Cloak setup complete"

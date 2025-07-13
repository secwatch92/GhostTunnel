#!/bin/bash
# Nginx, SSL, and Path Rotation Setup

source ./scripts/helpers.sh

SERVER_NAME="$1"
DOMAIN_NAME="$2"
EMAIL="$3"

status "Configuring Nginx for path rotation"
rm -f /etc/nginx/sites-enabled/default

INITIAL_PATH="/vpn-$(openssl rand -hex 4)"

# Nginx configuration
cat > /etc/nginx/sites-available/vpn <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    
    # For Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $SERVER_NAME;
    
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
    location $INITIAL_PATH {
        proxy_pass http://127.0.0.1:51820; # Pass to WireGuard via Cloak
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location / {
        return 404; # Or redirect to a real site
    }
}
EOF

ln -sf /etc/nginx/sites-available/vpn /etc/nginx/sites-enabled/
systemctl restart nginx
check_error "Failed to setup Nginx"

# SSL Certificate
if [ -n "$DOMAIN_NAME" ]; then
  status "Obtaining SSL certificate from Let's Encrypt for $DOMAIN_NAME"
  if [ -z "$EMAIL" ]; then
    certbot --nginx -d "$DOMAIN_NAME" --register-unsafely-without-email --non-interactive --agree-tos
  else
    certbot --nginx -d "$DOMAIN_NAME" -m "$EMAIL" --non-interactive --agree-tos
  fi
  check_error "Certbot failed to obtain SSL certificate"
  systemctl reload nginx
fi

# Path rotation script
cat > /usr/local/bin/rotate-path.sh <<'EOF'
#!/bin/bash
NGINX_CONF="/etc/nginx/sites-available/vpn"
CURRENT_PATH=$(grep -oP 'location\s*/vpn-\w+\s*\{' "$NGINX_CONF" | sed 's/location //;s/ {.*//')
NEW_PATH="/vpn-$(openssl rand -hex 4)"

if [ -n "$CURRENT_PATH" ]; then
    sed -i "s|$CURRENT_PATH|$NEW_PATH|g" "$NGINX_CONF"
    systemctl reload nginx
    echo "$(date) - Path rotated to: $NEW_PATH" >> /var/log/path-rotation.log
    echo "$NEW_PATH" > /var/www/html/current-path
else
    echo "$(date) - ERROR: Could not find current path to rotate." >> /var/log/path-rotation.log
fi
EOF

chmod +x /usr/local/bin/rotate-path.sh
mkdir -p /var/www/html
echo "$INITIAL_PATH" > /var/www/html/current-path

status "Nginx and SSL setup complete"

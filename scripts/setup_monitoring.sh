#!/bin/bash
# Resource Optimization and Monitoring Setup

source ./scripts/helpers.sh

PATH_ROTATION_INTERVAL="$1"

status "Optimizing system resources"

# Enable zRAM
if [ -f /etc/init.d/zram-config ]; then
    sed -i 's/PERCENT=.*/PERCENT=150/' /etc/init.d/zram-config
    systemctl restart zram-config
fi

# Create swap file
if ! swapon --show | grep -q '/swapfile'; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Resource limits for services
mkdir -p /etc/systemd/system/cloak.service.d
echo -e "[Service]\nMemoryMax=250M\nCPUQuota=40%" > /etc/systemd/system/cloak.service.d/limits.conf

mkdir -p /etc/systemd/system/wg-quick@wg0.service.d
echo -e "[Service]\nMemoryMax=150M\nCPUQuota=30%" > /etc/systemd/system/wg-quick@wg0.service.d/limits.conf

systemctl daemon-reload
status "Resource optimization complete"

# --- Monitoring and Maintenance ---
status "Configuring monitoring and maintenance"

# Resource monitor
cat > /usr/local/bin/resource-monitor.sh <<'EOF'
#!/bin/bash
LOG_FILE="/var/log/vpn-monitor.log"
MAX_RAM_MB=1700

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
RAM_USAGE=$(free -m | awk '/Mem:/ {print $3}')

echo "$(date) | CPU: ${CPU_USAGE}% | RAM: ${RAM_USAGE}MB" >> "$LOG_FILE"

if (( $(echo "$CPU_USAGE > 95" | bc -l) )) || [ "$RAM_USAGE" -gt "$MAX_RAM_MB" ]; then
  echo "$(date) - High load detected! Restarting services..." >> "$LOG_FILE"
  systemctl restart cloak wg-quick@wg0
fi
EOF
chmod +x /usr/local/bin/resource-monitor.sh

# Cleanup script with logrotate
cat > /etc/logrotate.d/vpn-monitor <<'EOF'
/var/log/vpn-monitor.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF

(crontab -l 2>/dev/null | grep -v "resource-monitor.sh" | grep -v "rotate-path.sh"; \
 echo "*/5 * * * * /usr/local/bin/resource-monitor.sh"; \
 echo "0 */$PATH_ROTATION_INTERVAL * * * /usr/local/bin/rotate-path.sh") | crontab -

status "Monitoring setup complete"

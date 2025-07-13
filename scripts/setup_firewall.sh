#!/bin/bash
# Firewall and Kernel Hardening Setup

source ./scripts/helpers.sh

status "Configuring basic security"

# Kernel security settings
cat >> /etc/sysctl.conf <<EOF
net.ipv4.icmp_echo_ignore_all=1
net.core.bpf_jit_harden=1
kernel.kptr_restrict=1
vm.swappiness=60
fs.protected_hardlinks=1
fs.protected_symlinks=1
EOF
sysctl -p
check_error "Failed to apply sysctl settings"

# Basic Firewall
iptables -P INPUT ACCEPT
iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -P INPUT DROP
netfilter-persistent save
check_error "Failed to configure iptables firewall"

status "Firewall and kernel hardening complete"

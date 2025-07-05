# GhostTunnel

**Your personal, untraceable gateway to the open internet.** 🌐🕵️‍♂️

---

## 🚀 What is GhostTunnel?

GhostTunnel is a powerful one-click VPN deployment script designed for stealth, security, and bypassing censorship.

It combines:
- 🛡️ **WireGuard** for blazing-fast encrypted tunneling  
- 👻 **Cloak** to disguise traffic as legitimate HTTPS activity  
- 🔁 **Nginx** for dynamic path rotation and optional domain support  
- 🧠 Smart automation for system hardening, resource monitoring, and self-recovery

This solution provides strong resistance against DPI (Deep Packet Inspection) and network filtering, all with minimal setup effort.

---

## ✨ Key Features

- 🔐 Full support for **domain & IP**
- 🔧 Single-file deployment script (Bash)
- 🎭 Traffic obfuscation with **Cloak**
- 🔄 Dynamic path rotation via **Nginx**
- 📦 Automatic SSL (Let’s Encrypt)
- 👥 Supports multiple users + QR Code generation
- 📊 Real-time monitoring + auto-heal services
- 🧠 System optimization with zRAM & swap
- 📁 Clean configuration structure: `/etc/wireguard/clients/`, `/etc/cloak/`, etc.

---

## 🖥️ Compatible With

- Ubuntu **22.04** and **24.04**
- x86_64 servers (VPS, cloud, bare metal)

---

## 📥 How to Use This Package

1. **Clone:** Clone the repository containing these files to your local machine or server.

2. **Configure:** Copy `config.sh.example` to `config.sh` and edit the variables inside to match your needs.

   Bash

   ```
   cp config.sh.example config.sh
   nano config.sh
   ```

3. **Set Permissions:** Make all the scripts executable.

   Bash

   ```
   chmod +x install.sh
   chmod +x scripts/*.sh
   ```

4. **Run:** Execute the main installer with `sudo`.

   Bash

   ```
   sudo ./install.sh
   ```

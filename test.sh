#!/bin/bash
# ============================================================
# Ubuntu 18.04 End-of-Life Hardening Script
# Author: J
# Purpose: Demonstrate post-EOL mitigation and CIA improvement
# ============================================================

LOG_DIR=~/lynis_reports
DATE=$(date +"%Y-%m-%d_%H-%M")
mkdir -p $LOG_DIR

echo "=== Starting baseline scans at $DATE ==="

# ------------------------------
# 1. Baseline Scans
# ------------------------------
echo "[*] Running Lynis baseline scan..."
sudo lynis audit system | tee $LOG_DIR/lynis_18.04_baseline_$DATE.log

echo "[*] Running Nmap baseline scan..."
sudo nmap -sS -T4 -p- localhost | tee $LOG_DIR/nmap_18.04_baseline_$DATE.txt

echo "[*] Running chkrootkit baseline scan..."
sudo chkrootkit | tee $LOG_DIR/chkrootkit_18.04_baseline_$DATE.txt

# ------------------------------
# 2. Hardening Measures
# ------------------------------
echo "=== Applying hardening measures... ==="

# Firewall setup
echo "[*] Enabling and configuring UFW firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh

# Disable unnecessary services
echo "[*] Disabling unused network services..."
for svc in avahi-daemon cups rpcbind; do
  sudo systemctl disable $svc 2>/dev/null
  sudo systemctl stop $svc 2>/dev/null
done

# SSH hardening
echo "[*] Securing SSH configuration..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Fail2Ban setup
echo "[*] Installing and enabling fail2ban..."
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# AppArmor setup
echo "[*] Enabling AppArmor..."
sudo systemctl enable apparmor
sudo systemctl start apparmor

# Network hardening
echo "[*] Applying sysctl network security tweaks..."
sudo bash -c 'cat >> /etc/sysctl.conf <<EOF

# Security Hardening Additions
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF'
sudo sysctl -p

# Optional ESM setup
echo "[*] Installing Ubuntu Advantage tools (for ESM)..."
sudo apt install ubuntu-advantage-tools -y

echo "=== Hardening applied successfully. Starting post-scan phase... ==="

# ------------------------------
# 3. Post-Hardening Scans
# ------------------------------
POST_DATE=$(date +"%Y-%m-%d_%H-%M")
echo "[*] Running Lynis post-hardening scan..."
sudo lynis audit system | tee $LOG_DIR/lynis_18.04_hardened_$POST_DATE.log

echo "[*] Running Nmap post-hardening scan..."
sudo nmap -sS -T4 -p- localhost | tee $LOG_DIR/nmap_18.04_hardened_$POST_DATE.txt

echo "[*] Running chkrootkit post-hardening scan..."
sudo chkrootkit | tee $LOG_DIR/chkrootkit_18.04_hardened_$POST_DATE.txt

# ------------------------------
# 4. Summary
# ------------------------------
echo "=== Hardening and rescan complete! ==="
echo "Reports stored in: $LOG_DIR"
ls -lh $LOG_DIR

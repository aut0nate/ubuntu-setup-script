#!/bin/bash
# arkham-dev1 Ubuntu 24.04 Initial Setup Script
# Author: Nathan
# Description: Configure and harden a fresh Ubuntu server

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
SSH_PORT=2222
USERNAME="nathan"
TIMEZONE="Europe/London"
LOCALE="en_GB.UTF-8"

# Functions
update_system() {
    echo "\nUpdating system packages..."
    sudo apt update && sudo apt upgrade -y
}

set_timezone() {
    echo "\nSetting timezone..."
    sudo timedatectl set-timezone "$TIMEZONE"
}

set_locale() {
    echo "\nSetting locale..."
    sudo locale-gen "$LOCALE"
    sudo update-locale LANG="$LOCALE"
}

harden_ssh() {
    echo "\nHardening SSH configuration..."
    sudo sed -i.bak \
        -e "s/^#Port .*/Port $SSH_PORT/" \
        -e "s/^#PermitRootLogin .*/PermitRootLogin no/" \
        -e "s/^#PasswordAuthentication .*/PasswordAuthentication no/" \
        -e "s/^#PubkeyAuthentication .*/PubkeyAuthentication yes/" \
        /etc/ssh/sshd_config

    # Allow only specific user (optional, uncomment if desired)
    if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
        echo "AllowUsers $USERNAME" | sudo tee -a /etc/ssh/sshd_config
    fi

    sudo systemctl restart sshd
}

configure_firewall() {
    echo "\nInstalling and configuring UFW..."
    sudo apt install ufw -y
    sudo ufw allow "$SSH_PORT"/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    sudo ufw status verbose
}

install_fail2ban() {
    echo -e "\n🚓 Installing and configuring Fail2Ban..."

    apt install fail2ban -y
    systemctl enable --now fail2ban

    # Backup the default config
    if [ ! -f /etc/fail2ban/jail.local ]; then
        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
        echo "✔️ Backed up jail.conf to jail.local"
    fi

    # Create custom jail overrides
    tee /etc/fail2ban/jail.d/customisation.local > /dev/null <<EOF
[DEFAULT]
bantime = 1h

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 4h
EOF

    systemctl restart fail2ban

    echo -e "\n✅ Fail2Ban installed and configured."
    echo -e "🚨 Current Fail2Ban SSHD jail status:"
    fail2ban-client status sshd || echo "(⚠️ Note: sshd jail may not show until first attempt to login)"
}

enable_auto_updates() {
    echo "\nSetting up automatic security updates..."
    sudo apt install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
}

install_tailscale() {
    echo "\nInstalling Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
}

install_docker() {
    echo "\nInstalling Docker and Docker Compose..."
    sudo apt install -y docker.io docker-compose

    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USERNAME"
}

# Execution
update_system
set_timezone
set_locale
harden_ssh
configure_firewall
install_fail2ban
enable_auto_updates
install_tailscale
install_docker

# Final message
echo "\n✅ Setup complete. Please log out and back in to apply Docker group permissions."
echo "\n⚠️ Remember to run 'tailscale up' to connect your server to your Tailscale network."

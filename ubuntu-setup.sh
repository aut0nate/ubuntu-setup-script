#!/bin/bash
# arkham-dev1 Ubuntu 24.04 Initial Setup Script
# Author: Nathan
# Description: Configure and harden a fresh Ubuntu server

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail

# Variables
SSH_PORT=1985
USERNAME="nathan"
USER_SHELL="/bin/bash"
TIMEZONE="Europe/London"
LOCALE="en_GB.UTF-8"

# Functions
update_system() {
    echo -e "\n📦 Updating system packages..."
    apt update && apt upgrade -y
}

create_user() {
    echo -e "\n👤 Creating new user: $USERNAME..."
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists, skipping creation."
    else
        useradd -m -s "$USER_SHELL" -G sudo "$USERNAME"
        echo "User $USERNAME created and added to sudo group."
    fi
}

set_timezone() {
    echo -e "\n🌍 Setting timezone..."
    timedatectl set-timezone "$TIMEZONE"
}

set_locale() {
    echo -e "\n🗣️ Setting locale..."
    locale-gen "$LOCALE"
    update-locale LANG="$LOCALE"
}

harden_ssh() {
    echo -e "\n🔒 Hardening SSH configuration..."

    # Configure ssh.socket to listen on the new port
    mkdir -p /etc/systemd/system/ssh.socket.d
    tee /etc/systemd/system/ssh.socket.d/listen.conf > /dev/null <<EOF
[Socket]
ListenStream=
ListenStream=$SSH_PORT
EOF

    systemctl daemon-reload
    systemctl restart ssh.socket

    # Update SSH configuration
    SSHD_CLOUD_INIT_FILE="/etc/ssh/sshd_config.d/50-cloud-init.conf"
    if [ -f "$SSHD_CLOUD_INIT_FILE" ]; then
        sed -i.bak -E \
            -e "s/^#?PasswordAuthentication.*/PasswordAuthentication no/" \
            -e "s/^#?PermitRootLogin.*/PermitRootLogin no/" \
            "$SSHD_CLOUD_INIT_FILE"
    fi

    # Ensure PubkeyAuthentication is enforced
    sed -i.bak -E \
        -e "s/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/" \
        /etc/ssh/sshd_config

    # Restrict SSH access to the new user
    if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
        echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config
    fi

    systemctl restart ssh
    systemctl enable ssh
    echo -e "✅ SSH hardened: Root login disabled, password auth disabled, port changed to $SSH_PORT"
}

configure_firewall() {
    echo -e "\n🛡️ Installing and configuring UFW..."
    apt install ufw -y
    ufw allow "$SSH_PORT"/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    ufw status verbose
}

install_fail2ban() {
    echo -e "\n🚓 Installing Fail2Ban..."
    apt install fail2ban -y
    systemctl enable --now fail2ban
}

enable_auto_updates() {
    echo -e "\n🔄 Setting up automatic security updates..."
    apt install unattended-upgrades -y
    dpkg-reconfigure --priority=low unattended-upgrades
}

install_tailscale() {
    echo -e "\n🌐 Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
}

install_docker() {
    echo -e "\n🐳 Installing Docker and Docker Compose..."
    apt install -y docker.io docker-compose

    systemctl enable --now docker
    usermod -aG docker "$USERNAME"
}

# Main Execution Flow
update_system
create_user
set_timezone
set_locale
harden_ssh
configure_firewall
install_fail2ban
enable_auto_updates
install_tailscale
install_docker

# Final message
echo -e "✅ Setup complete for $USERNAME!"
echo -e "⚠️ Please log out and back in to apply Docker group permissions."
echo -e "⚠️ Run 'sudo tailscale up' to connect the server to your Tailscale network."
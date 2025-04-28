# Ubuntu Server Setup Script

This script automates the initial configuration and hardening of a fresh Ubuntu server.

It was built for personal use with a focus on security, best practices, and future expandability.

## Features

- System update and upgrade
- User creation with sudo access
- Timezone and locale configuration
- SSH hardening:
  - Disable root login
  - Disable password authentication
  - Change SSH port
  - Restrict SSH login to a specific user
- UFW firewall installation and configuration
- Fail2Ban installation and custom configuration
- Automatic security updates
- Tailscale installation
- Docker and Docker Compose installation

## Variables

| **Variable**                               | **Purpose**                                                              |
|-------------------------------------------|------------------------------------------------------------------------------|
| `SSH_PORT`                                    | New SSH port (default: 2222)                                                   |
| `USERNAME`                   | New user to create (default: nathan)                         |
| `USER_SHELL`                 | Shell for the user (default: /bin/bash)      |
| `TIMEZONE`                   | System timezone (default: Europe/London)     |
| `LOCALE`                     | System locale (default: en_GB.UTF-8)         |

## How to Use

1. SSH into your fresh server as `root`.
2. Copy the script to the server.
3. Edit the script variables at the top if needed (e.g., `USERNAME`, `SSH_PORT`).
4. Make the script executable:

   ```bash
   chmod +x setup.sh
   ```

5. Run the script:

    ```bash
    sudo ./setup.sh
    ```

## Important

- Always keep your existing SSH session open when making SSH-related changes (in case you need to fix connection issues).
- After running the script, log out and log back in to apply group changes (especially for Docker access).

## Requirements

- Ubuntu Server (fresh install recommended)
- SSH access with a key pair already set up (password login disabled during setup)

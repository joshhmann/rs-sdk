# 2004scape LXC Deployment

This directory contains scripts and configuration files for deploying the 2004scape server on a Linux container (LXC) or a fresh Debian/Ubuntu server. This is ideal for homelab setups where you want a persistent game world running 24/7.

## Prerequisites

-   A machine running Proxmox VE (or any LXC host).
-   A container running **Debian 12 (Bookworm)** or **Ubuntu 24.04**.
-   Internet access for the container.

## Server Specification Recommendation

-   **CPU**: 2 cores
-   **RAM**: 2GB (minimum), 4GB (recommended)
-   **Disk**: 10GB+

## Quick Start (Proxmox/LXC)

1.  **Create a Container**:
    -   Use the Proxmox GUI or `pct` to create a new Debian 12 container.
    -   Ensure "Nesting" is enabled if you plan to do advanced things later (optional for this setup).
    -   Start the container.

2.  **Access the Container**:
    -   Open the Console or SSH into the container.
    -   Login as `root`.

3.  **Run the Installer**:
    One-line command to install and start services (assuming you have this repo or just want to pull it):

    ```bash
    # Install curl and git if missing
    apt update && apt install -y curl git
    
    # Clone the repo (if not already present) to /opt/rs-sdk
    # Or navigate to your existing repo clone if you copied it manually.
    
    # Run the installer
    curl -fsSL https://raw.githubusercontent.com/joshhmann/rs-sdk/main/deploy/lxc/install.sh | bash
    ```

    *Note: The above URL assumes this PR is merged. For local testing, copy `deploy/lxc/install.sh` to your container and run it: `./install.sh`*

## What it does

The `install.sh` script will:

1.  Install system dependencies: `curl`, `git`, `unzip`, `java` (default-jre-headless), `xvfb`, `chromium`, `bun`.
2.  Clone/Pull the `rs-sdk` repository to `/opt/rs-sdk`.
3.  Install project dependencies via `bun install`.
4.  Build the webclient and deploy assets to the engine.
5.  Set up `rs-engine` and `rs-gateway` as systemd services.
6.  Start the services automatically on boot.

## Managing the Server

-   Check status: `systemctl status rs-engine rs-gateway`
-   Restart server: `systemctl restart rs-engine`
-   View logs: `journalctl -u rs-engine -f`

## Configuration

The bot configuration is located at `/opt/rs-sdk/bots/agent/bot.env`. You can edit this file to change the bot credentials or server connection settings.

The default configuration connects to `localhost`. If you want to connect external clients, the gateway listens on port `7780` and the engine on `8888`.

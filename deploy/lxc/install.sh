#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting 2004scape LXC Installer...${NC}"

# 1. Install System Dependencies
echo -e "${GREEN}Installing system dependencies...${NC}"
# chromium installation can be tricky on minimal containers, adding xvfb and ffmpeg as extras
apt-get update
# Note: we use chromium from repo. Dockerfile uses specific chromium version sometimes.
apt-get install -y curl git unzip default-jre-headless xvfb ffmpeg chromium procps

# 2. Install Bun
if [ ! -d "$HOME/.bun" ]; then
    echo -e "${GREEN}Installing Bun...${NC}"
    curl -fsSL https://bun.sh/install | bash
fi
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# 3. Setup App Directory
# Default to /opt/rs-sdk but allow override via env var
APP_DIR="${APP_DIR:-/opt/rs-sdk}"
echo -e "${GREEN}Using App Directory: $APP_DIR${NC}"

if [ ! -d "$APP_DIR" ]; then
    echo -e "${GREEN}Cloning rs-sdk repository...${NC}"
    # Use the current user's repo or upstream if not specified.
    # Ideally this script is part of the repo, so we might copy it?
    # For now, we clone the main repo.
    git clone https://github.com/joshhmann/rs-sdk.git "$APP_DIR"
else
    echo -e "${GREEN}Updating existing repository in $APP_DIR...${NC}"
    cd "$APP_DIR" && git pull || echo "Repo update failed, continuing..."
fi

cd "$APP_DIR"

# 4. Install Project Dependencies
echo -e "${GREEN}Installing project dependencies...${NC}"
bun install

echo -e "${GREEN}Installing Engine dependencies...${NC}"
cd server/engine && bun install

echo -e "${GREEN}Installing Gateway dependencies...${NC}"
cd ../gateway && bun install

echo -e "${GREEN}Building Webclient...${NC}"
cd ../webclient && bun install && bun run build

# 5. Asset Copy
echo -e "${GREEN}Deploying webclient assets to engine...${NC}"
cd "$APP_DIR"
mkdir -p server/engine/public/bot
# Ensure the destination is clean or just overwrite
cp -r server/webclient/out/bot/* server/engine/public/bot/

# 6. Bot Configuration
echo -e "${GREEN}Setting up default bot configuration...${NC}"
mkdir -p bots/agent
if [ ! -f "bots/agent/bot.env" ]; then
    # Create default env if not exists
    echo "BOT_USERNAME=agent" > bots/agent/bot.env
    echo "PASSWORD=test" >> bots/agent/bot.env
    echo "SHOW_CHAT=false" >> bots/agent/bot.env
    echo "SERVER=localhost" >> bots/agent/bot.env
fi

# 7. Install Systemd Services
echo -e "${GREEN}Installing systemd services...${NC}"

# Copy service files from the repo
if [ -f "deploy/lxc/rs-engine.service" ]; then
    cp deploy/lxc/rs-engine.service /etc/systemd/system/
    cp deploy/lxc/rs-gateway.service /etc/systemd/system/
else
    echo -e "${GREEN}Service files not found in deploy/lxc. Downloading from source or skipping...${NC}"
    # In a real scenario, we might want to cat them here if they aren't in the repo yet.
    # But since we are committing them to the repo, they should be there after a pull.
fi

# Reload systemd
systemctl daemon-reload
systemctl enable rs-engine
systemctl enable rs-gateway

echo -e "${GREEN}Starting services...${NC}"
systemctl restart rs-engine
systemctl restart rs-gateway

echo -e "${GREEN}Installation Complete!${NC}"
echo "Engine running on port 8888"
echo "Gateway running on port 7780"

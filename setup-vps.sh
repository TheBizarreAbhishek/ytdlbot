#!/bin/bash
# One-Command VPS Setup Script for ytdlbot
# Run: curl -fsSL https://raw.githubusercontent.com/TheBizarreAbhishek/ytdlbot/master/setup-vps.sh | bash

set -e

echo "========================================="
echo "  ytdlbot VPS Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${YELLOW}Running as root. This is OK for VPS setup.${NC}"
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo -e "${GREEN}Docker installed!${NC}"
else
    echo -e "${GREEN}Docker already installed.${NC}"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose installed!${NC}"
else
    echo -e "${GREEN}Docker Compose already installed.${NC}"
fi

# Clone or update repository
if [ -d "ytdlbot" ]; then
    echo -e "${YELLOW}Repository exists, updating...${NC}"
    cd ytdlbot
    git pull
else
    echo -e "${YELLOW}Cloning ytdlbot repository...${NC}"
    git clone https://github.com/TheBizarreAbhishek/ytdlbot.git
    cd ytdlbot
fi

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo ""
    echo -e "${YELLOW}=========================================${NC}"
    echo -e "${YELLOW}  Configuration Required${NC}"
    echo -e "${YELLOW}=========================================${NC}"
    echo ""
    echo "You need to provide the following:"
    echo "1. APP_ID and APP_HASH from https://my.telegram.org/apps"
    echo "2. Your Telegram User ID (message @userinfobot on Telegram)"
    echo "3. A secure password for MySQL database"
    echo ""
    
    cp .env.example .env
    
    read -p "Enter your Telegram APP_ID: " APP_ID
    read -p "Enter your Telegram APP_HASH: " APP_HASH
    read -p "Enter your Telegram User ID: " USER_ID
    read -sp "Enter MySQL password (min 8 chars): " MYSQL_PASS
    echo ""
    
    # Validate inputs
    if [ -z "$APP_ID" ] || [ -z "$APP_HASH" ] || [ -z "$USER_ID" ] || [ -z "$MYSQL_PASS" ]; then
        echo -e "${RED}Error: All fields are required!${NC}"
        exit 1
    fi
    
    if [ ${#MYSQL_PASS} -lt 8 ]; then
        echo -e "${RED}Error: MySQL password must be at least 8 characters!${NC}"
        exit 1
    fi
    
    # Update .env file
    sed -i "s/^APP_ID=.*/APP_ID=$APP_ID/" .env
    sed -i "s/^APP_HASH=.*/APP_HASH=$APP_HASH/" .env
    sed -i "s/^BOT_TOKEN=.*/BOT_TOKEN=8247631826:AAE_zYrmB1C6umRufEM3SMr7ytC7eAMCcsA/" .env
    sed -i "s/^OWNER=.*/OWNER=$USER_ID/" .env
    sed -i "s|^DB_DSN=.*|DB_DSN=mysql+pymysql://ytdlbot:$MYSQL_PASS@mysql/ytdlbot|" .env
    
    # Enable recommended features
    sed -i "s/^ENABLE_FFMPEG=.*/ENABLE_FFMPEG=True/" .env
    sed -i "s/^ENABLE_ARIA2=.*/ENABLE_ARIA2=True/" .env
    sed -i "s/^FREE_DOWNLOAD=.*/FREE_DOWNLOAD=5/" .env
    
    # Update docker-compose.yml with MySQL password
    if ! grep -q "MYSQL_PASSWORD" docker-compose.yml; then
        # Add MySQL environment variables after MYSQL_ROOT_PASSWORD
        sed -i '/MYSQL_ROOT_PASSWORD/a\      MYSQL_DATABASE: "ytdlbot"\n      MYSQL_USER: "ytdlbot"\n      MYSQL_PASSWORD: "'"$MYSQL_PASS"'"' docker-compose.yml
    else
        sed -i "s/MYSQL_PASSWORD:.*/MYSQL_PASSWORD: \"$MYSQL_PASS\"/" docker-compose.yml
    fi
    
    echo -e "${GREEN}Configuration saved!${NC}"
else
    echo -e "${GREEN}.env file already exists. Skipping configuration.${NC}"
    echo "If you need to reconfigure, delete .env and run this script again."
fi

# Start services
echo ""
echo -e "${YELLOW}Starting Docker containers...${NC}"
docker-compose down 2>/dev/null || true
docker-compose up -d

echo ""
echo -e "${YELLOW}Waiting for services to initialize (15 seconds)...${NC}"
sleep 15

# Check service status
echo ""
echo -e "${YELLOW}Checking service status...${NC}"
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}Services are running!${NC}"
    docker-compose ps
else
    echo -e "${RED}Some services may not be running. Check logs with: docker-compose logs${NC}"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Your bot should now be running!"
echo ""
echo "Useful commands:"
echo "  View logs:    docker-compose logs -f ytdl"
echo "  Restart:     docker-compose restart ytdl"
echo "  Stop:        docker-compose down"
echo "  Status:      docker-compose ps"
echo ""
echo "Test your bot by sending /start on Telegram"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Revoke the test bot token after testing!${NC}"
echo ""


#!/bin/bash
# One-Command Native VPS Setup Script for ytdlbot (No Docker)
# Run: curl -fsSL https://raw.githubusercontent.com/TheBizarreAbhishek/ytdlbot/master/setup-native.sh | bash

set -e

echo "========================================="
echo "  ytdlbot Native VPS Setup (No Docker)"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo -e "${YELLOW}This script needs to be run as root for installing system packages.${NC}"
   echo "Please run: sudo bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/TheBizarreAbhishek/ytdlbot/master/setup-native.sh)\""
   exit 1
fi

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt update && apt upgrade -y

# Install system dependencies
echo -e "${YELLOW}Installing system dependencies...${NC}"
apt install -y python3 python3-pip python3-venv git ffmpeg aria2 redis-server sqlite3

# Start Redis
echo -e "${YELLOW}Starting Redis...${NC}"
service redis-server start 2>/dev/null || systemctl start redis-server 2>/dev/null || true

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

# Create Python virtual environment
echo -e "${YELLOW}Setting up Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip

# Install Python dependencies
echo -e "${YELLOW}Installing Python dependencies (this may take a few minutes)...${NC}"
pip install -r requirements.txt

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
    echo ""
    
    read -p "Enter your Telegram APP_ID: " APP_ID
    read -p "Enter your Telegram APP_HASH: " APP_HASH
    read -p "Enter your Telegram User ID: " USER_ID
    
    # Validate inputs
    if [ -z "$APP_ID" ] || [ -z "$APP_HASH" ] || [ -z "$USER_ID" ]; then
        echo -e "${RED}Error: All fields are required!${NC}"
        exit 1
    fi
    
    # Create .env file with SQLite (simpler than MySQL)
    cat > .env << EOF
WORKERS=100
APP_ID=$APP_ID
APP_HASH=$APP_HASH
BOT_TOKEN=8247631826:AAE_zYrmB1C6umRufEM3SMr7ytC7eAMCcsA
OWNER=$USER_ID
AUTHORIZED_USER=
DB_DSN=sqlite:///db.sqlite
REDIS_HOST=
ENABLE_FFMPEG=True
ENABLE_ARIA2=True
FREE_DOWNLOAD=5
TMPFILE_PATH=/tmp/ytdlbot
EOF
    
    echo -e "${GREEN}Configuration saved!${NC}"
else
    echo -e "${GREEN}.env file already exists. Skipping configuration.${NC}"
    echo "If you need to reconfigure, delete .env and run this script again."
fi

# Create temp directory
echo -e "${YELLOW}Creating temp directory...${NC}"
mkdir -p /tmp/ytdlbot
chmod 777 /tmp/ytdlbot

# Create database file
touch db.sqlite
chmod 666 db.sqlite

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Your bot is ready to run!"
echo ""
echo "To start the bot:"
echo "  cd $(pwd)"
echo "  source venv/bin/activate"
echo "  python src/main.py"
echo ""
echo "Or run in background:"
echo "  nohup python src/main.py > bot.log 2>&1 &"
echo ""
echo "To stop the bot:"
echo "  pkill -f 'python src/main.py'"
echo ""
echo "To view logs:"
echo "  tail -f bot.log"
echo ""
echo "Test your bot by sending /start on Telegram"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Revoke the test bot token after testing!${NC}"
echo ""


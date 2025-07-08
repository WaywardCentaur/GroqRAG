#!/bin/bash

# Anna Webinar Demo - Vultr Deployment Script
# This script deploys the React frontend to a Vultr VPS at 45.32.212.233

set -e

# Configuration
VPS_IP="45.32.212.233"
VPS_USER="root"
APP_NAME="anna-webinar-demo"
DEPLOY_DIR="/opt/${APP_NAME}"
DOMAIN="45.32.212.233"  # Can be changed to a domain name later

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting deployment of Anna Webinar Demo to Vultr VPS${NC}"
echo -e "${YELLOW}Target: ${VPS_USER}@${VPS_IP}${NC}"

# Function to run commands on remote server
run_remote() {
    ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} "$1"
}

# Function to copy files to remote server
copy_to_remote() {
    scp -o StrictHostKeyChecking=no -r "$1" ${VPS_USER}@${VPS_IP}:"$2"
}

echo -e "${YELLOW}📋 Step 1: Checking local prerequisites${NC}"

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: package.json not found. Please run this script from the anna-webinar-demo directory.${NC}"
    exit 1
fi

# Check if Docker is installed locally
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed locally.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Local prerequisites met${NC}"

echo -e "${YELLOW}📋 Step 2: Testing SSH connection to VPS${NC}"

# Test SSH connection
if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${VPS_USER}@${VPS_IP} "echo 'SSH connection successful'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to VPS via SSH. Please check:${NC}"
    echo -e "${RED}   - VPS IP address (${VPS_IP})${NC}"
    echo -e "${RED}   - SSH key configuration${NC}"
    echo -e "${RED}   - VPS accessibility${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH connection to VPS successful${NC}"

echo -e "${YELLOW}📋 Step 3: Installing Docker on VPS (if needed)${NC}"

# Install Docker on VPS if not already installed
run_remote "
    if ! command -v docker &> /dev/null; then
        echo 'Installing Docker...'
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        rm get-docker.sh
    else
        echo 'Docker already installed'
    fi
"

# Install Docker Compose if not already installed
run_remote "
    if ! command -v docker-compose &> /dev/null; then
        echo 'Installing Docker Compose...'
        curl -L \"https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    else
        echo 'Docker Compose already installed'
    fi
"

echo -e "${GREEN}✅ Docker installation completed${NC}"

echo -e "${YELLOW}📋 Step 4: Preparing deployment directory${NC}"

# Create deployment directory
run_remote "
    mkdir -p ${DEPLOY_DIR}
    cd ${DEPLOY_DIR}
    
    # Stop and remove existing containers if they exist
    if [ -f docker-compose.yml ]; then
        docker-compose down --remove-orphans || true
    fi
    
    # Clean up old files but keep logs
    find . -maxdepth 1 -not -name logs -not -name . -exec rm -rf {} + 2>/dev/null || true
"

echo -e "${GREEN}✅ Deployment directory prepared${NC}"

echo -e "${YELLOW}📋 Step 5: Building and transferring application${NC}"

# Create a temporary build directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Copy project files to temp directory
cp -r . "$TEMP_DIR/"

# Remove node_modules and build if they exist
rm -rf "$TEMP_DIR/node_modules" "$TEMP_DIR/build" 2>/dev/null || true

# Copy files to VPS
copy_to_remote "$TEMP_DIR/*" "${DEPLOY_DIR}/"

# Cleanup temp directory
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Application files transferred${NC}"

echo -e "${YELLOW}📋 Step 6: Building and starting application${NC}"

# Build and start the application
run_remote "
    cd ${DEPLOY_DIR}
    
    # Build the Docker image
    echo 'Building Docker image...'
    docker build -t ${APP_NAME}:latest .
    
    # Start the application with Docker Compose
    echo 'Starting application...'
    docker-compose up -d
    
    # Wait a moment for the container to start
    sleep 5
    
    # Check if the container is running
    if docker-compose ps | grep -q 'Up'; then
        echo 'Application started successfully!'
    else
        echo 'Warning: Application may not have started correctly'
        docker-compose logs
    fi
"

echo -e "${GREEN}✅ Application deployed and started${NC}"

echo -e "${YELLOW}📋 Step 7: Configuring firewall${NC}"

# Configure UFW firewall to allow necessary ports
run_remote "
    # Enable UFW if not already enabled
    ufw --force enable
    
    # Allow SSH (port 22)
    ufw allow ssh
    
    # Allow HTTP (port 80)
    ufw allow 80
    
    # Allow the application port (3000)
    ufw allow 3000
    
    # Allow HTTPS (port 443) for future use
    ufw allow 443
    
    # Show status
    ufw status
"

echo -e "${GREEN}✅ Firewall configured${NC}"

echo -e "${YELLOW}📋 Step 8: Final health check${NC}"

# Wait a moment for everything to settle
sleep 10

# Check if the application is responding
if run_remote "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000" | grep -q "200"; then
    echo -e "${GREEN}✅ Application health check passed${NC}"
else
    echo -e "${YELLOW}⚠️  Application may still be starting. Checking logs...${NC}"
    run_remote "cd ${DEPLOY_DIR} && docker-compose logs --tail=20"
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📱 Your Anna Webinar Demo is now available at:${NC}"
echo -e "${GREEN}   🌐 http://${VPS_IP}:3000${NC}"
echo ""
echo -e "${BLUE}📊 Useful commands:${NC}"
echo -e "${YELLOW}   # View logs:${NC}"
echo -e "   ssh ${VPS_USER}@${VPS_IP} 'cd ${DEPLOY_DIR} && docker-compose logs -f'"
echo ""
echo -e "${YELLOW}   # Restart application:${NC}"
echo -e "   ssh ${VPS_USER}@${VPS_IP} 'cd ${DEPLOY_DIR} && docker-compose restart'"
echo ""
echo -e "${YELLOW}   # Stop application:${NC}"
echo -e "   ssh ${VPS_USER}@${VPS_IP} 'cd ${DEPLOY_DIR} && docker-compose down'"
echo ""
echo -e "${YELLOW}   # Update application:${NC}"
echo -e "   ./deploy-to-vultr.sh"
echo ""
echo -e "${BLUE}🔧 Configuration:${NC}"
echo -e "${YELLOW}   - Frontend URL: http://${VPS_IP}:3000${NC}"
echo -e "${YELLOW}   - Backend API: http://${VPS_IP}:8000${NC}"
echo -e "${YELLOW}   - WebSocket: ws://${VPS_IP}:8000${NC}"
echo ""
echo -e "${GREEN}✨ Deployment completed at $(date)${NC}"

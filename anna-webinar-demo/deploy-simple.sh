#!/bin/bash

# Simple deployment script for Anna Webinar Demo
# Works with both SSH keys and password authentication

set -e

VPS_IP="45.32.212.233"
VPS_USER="root"
APP_NAME="anna-webinar-demo"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Anna Webinar Demo - Simple Deployment${NC}"
echo -e "${YELLOW}Target: ${VPS_USER}@${VPS_IP}${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: Run this script from the anna-webinar-demo directory${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Step 1: Building the application locally${NC}"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Build the application
echo "Building for production..."
npm run build

echo -e "${GREEN}✅ Application built successfully${NC}"

echo -e "${YELLOW}📦 Step 2: Creating deployment package${NC}"

# Create deployment package
DEPLOY_PACKAGE="anna-webinar-deploy-$(date +%Y%m%d-%H%M%S).tar.gz"

tar -czf "$DEPLOY_PACKAGE" \
    build/ \
    Dockerfile \
    nginx.conf \
    docker-compose.yml \
    docker-entrypoint.sh \
    .env.production

echo -e "${GREEN}✅ Deployment package created: $DEPLOY_PACKAGE${NC}"

echo -e "${YELLOW}📤 Step 3: Uploading to VPS${NC}"
echo -e "${BLUE}You will be prompted for the VPS password if SSH keys are not configured.${NC}"

# Upload the package
if scp -o StrictHostKeyChecking=no "$DEPLOY_PACKAGE" ${VPS_USER}@${VPS_IP}:/tmp/; then
    echo -e "${GREEN}✅ Package uploaded successfully${NC}"
else
    echo -e "${RED}❌ Failed to upload package. Please check your SSH connection.${NC}"
    echo -e "${YELLOW}💡 Try: ssh ${VPS_USER}@${VPS_IP}${NC}"
    exit 1
fi

echo -e "${YELLOW}🏗️  Step 4: Deploying on VPS${NC}"

# Deploy on VPS
ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} << 'ENDSSH'
set -e

APP_NAME="anna-webinar-demo"
DEPLOY_DIR="/opt/${APP_NAME}"

echo "Installing Docker if needed..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
    rm get-docker.sh
fi

if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

echo "Setting up deployment directory..."
mkdir -p ${DEPLOY_DIR}
cd ${DEPLOY_DIR}

# Stop existing containers
if [ -f docker-compose.yml ]; then
    docker-compose down --remove-orphans || true
fi

# Clean up old files
find . -maxdepth 1 -not -name logs -not -name . -exec rm -rf {} + 2>/dev/null || true

echo "Extracting new deployment..."
tar -xzf /tmp/anna-webinar-deploy-*.tar.gz -C .

echo "Building and starting application..."
docker build -t ${APP_NAME}:latest .

# Update docker-compose to use built image
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  anna-webinar-demo:
    image: anna-webinar-demo:latest
    ports:
      - "3000:80"
    environment:
      - REACT_APP_API_URL=http://45.32.212.233:8000
      - REACT_APP_WS_URL=ws://45.32.212.233:8000
      - REACT_APP_ENV=production
    restart: unless-stopped
    container_name: anna-webinar-demo
EOF

docker-compose up -d

echo "Configuring firewall..."
ufw --force enable > /dev/null 2>&1 || true
ufw allow ssh > /dev/null 2>&1 || true
ufw allow 80 > /dev/null 2>&1 || true
ufw allow 3000 > /dev/null 2>&1 || true
ufw allow 443 > /dev/null 2>&1 || true

echo "Cleaning up deployment package..."
rm -f /tmp/anna-webinar-deploy-*.tar.gz

echo "Deployment completed!"
ENDSSH

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    
    # Clean up local package
    rm -f "$DEPLOY_PACKAGE"
    
    echo ""
    echo -e "${BLUE}🎉 Your Anna Webinar Demo is now running!${NC}"
    echo -e "${GREEN}🌐 Access it at: http://${VPS_IP}:3000${NC}"
    echo ""
    echo -e "${YELLOW}📊 Useful commands:${NC}"
    echo -e "${BLUE}   Check status: ssh ${VPS_USER}@${VPS_IP} 'docker ps'${NC}"
    echo -e "${BLUE}   View logs:    ssh ${VPS_USER}@${VPS_IP} 'cd /opt/${APP_NAME} && docker-compose logs'${NC}"
    echo -e "${BLUE}   Restart:      ssh ${VPS_USER}@${VPS_IP} 'cd /opt/${APP_NAME} && docker-compose restart'${NC}"
    
    echo ""
    echo -e "${YELLOW}🧪 Testing deployment...${NC}"
    sleep 5
    
    if curl -s -o /dev/null -w '%{http_code}' http://${VPS_IP}:3000 2>/dev/null | grep -q "200"; then
        echo -e "${GREEN}✅ Application is responding correctly!${NC}"
    else
        echo -e "${YELLOW}⚠️  Application may still be starting. Check in a few moments.${NC}"
    fi
else
    echo -e "${RED}❌ Deployment failed. Check the error messages above.${NC}"
    exit 1
fi

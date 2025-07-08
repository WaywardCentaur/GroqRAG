#!/bin/bash

# Comprehensive deployment status check for Anna Webinar Demo
# This script verifies both frontend and backend connectivity before deployment

set -e

# Configuration
FRONTEND_IP="45.32.212.233"
BACKEND_IP="149.28.123.26"
VPS_USER="root"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Anna Webinar Demo - Comprehensive Deployment Check${NC}"
echo -e "${YELLOW}Frontend Target: ${FRONTEND_IP}${NC}"
echo -e "${YELLOW}Backend Target: ${BACKEND_IP}${NC}"
echo ""

# Check backend server status
echo -e "${BLUE}📡 Checking Backend Server (${BACKEND_IP}:8000)${NC}"
echo "1. Testing backend health endpoint..."
if curl -s -m 10 -o /dev/null -w '%{http_code}' http://${BACKEND_IP}:8000/health 2>/dev/null | grep -q "200"; then
    echo -e "   ${GREEN}✅ Backend health check passed${NC}"
    BACKEND_STATUS="online"
else
    echo -e "   ${RED}❌ Backend health check failed${NC}"
    echo -e "   ${YELLOW}💡 The backend server may not be running or accessible${NC}"
    BACKEND_STATUS="offline"
fi

echo "2. Testing backend query endpoint..."
if curl -s -m 10 -o /dev/null -w '%{http_code}' http://${BACKEND_IP}:8000/query 2>/dev/null | grep -q "422\|405\|200"; then
    echo -e "   ${GREEN}✅ Backend query endpoint is accessible${NC}"
else
    echo -e "   ${RED}❌ Backend query endpoint is not accessible${NC}"
fi

echo "3. Testing WebSocket endpoint (basic connectivity)..."
if nc -z -w 5 ${BACKEND_IP} 8000 2>/dev/null; then
    echo -e "   ${GREEN}✅ Backend port 8000 is open${NC}"
else
    echo -e "   ${RED}❌ Backend port 8000 is not accessible${NC}"
fi

echo ""

# Check frontend server status
echo -e "${BLUE}🌐 Checking Frontend Server (${FRONTEND_IP})${NC}"
echo "1. Testing SSH connection to frontend server..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${VPS_USER}@${FRONTEND_IP} "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ SSH connection to frontend server successful${NC}"
    FRONTEND_SSH="ok"
else
    echo -e "   ${RED}❌ SSH connection to frontend server failed${NC}"
    FRONTEND_SSH="failed"
fi

echo "2. Checking if frontend port 3000 is available..."
if nc -z -w 5 ${FRONTEND_IP} 3000 2>/dev/null; then
    echo -e "   ${YELLOW}⚠️  Port 3000 is already in use (existing deployment?)${NC}"
else
    echo -e "   ${GREEN}✅ Port 3000 is available for deployment${NC}"
fi

echo ""

# Local build check
echo -e "${BLUE}🏗️  Checking Local Build${NC}"
echo "1. Verifying build directory exists..."
if [ -d "./build" ]; then
    echo -e "   ${GREEN}✅ Build directory exists${NC}"
    echo "2. Checking build size..."
    BUILD_SIZE=$(du -sh ./build | cut -f1)
    echo -e "   ${GREEN}✅ Build size: ${BUILD_SIZE}${NC}"
else
    echo -e "   ${RED}❌ Build directory not found${NC}"
    echo -e "   ${YELLOW}💡 Run 'npm run build' first${NC}"
fi

echo ""

# Environment configuration check
echo -e "${BLUE}⚙️  Checking Environment Configuration${NC}"
echo "1. Checking production environment file..."
if [ -f "./.env.production" ]; then
    echo -e "   ${GREEN}✅ Production environment file exists${NC}"
    echo "   Configuration:"
    grep -E "REACT_APP_" ./.env.production | sed 's/^/     /'
else
    echo -e "   ${RED}❌ Production environment file not found${NC}"
fi

echo ""

# Summary and recommendations
echo -e "${BLUE}📋 Deployment Readiness Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$BACKEND_STATUS" = "online" ]; then
    echo -e "Backend Server: ${GREEN}✅ READY${NC}"
else
    echo -e "Backend Server: ${RED}❌ NOT READY${NC}"
    echo -e "  ${YELLOW}→ Start the backend server at ${BACKEND_IP}:8000${NC}"
fi

if [ "$FRONTEND_SSH" = "ok" ]; then
    echo -e "Frontend Server: ${GREEN}✅ READY${NC}"
else
    echo -e "Frontend Server: ${RED}❌ NOT READY${NC}"
    echo -e "  ${YELLOW}→ Check SSH access to ${FRONTEND_IP}${NC}"
fi

if [ -d "./build" ]; then
    echo -e "Local Build: ${GREEN}✅ READY${NC}"
else
    echo -e "Local Build: ${RED}❌ NOT READY${NC}"
    echo -e "  ${YELLOW}→ Run 'npm run build' to create production build${NC}"
fi

echo ""

if [ "$BACKEND_STATUS" = "online" ] && [ "$FRONTEND_SSH" = "ok" ] && [ -d "./build" ]; then
    echo -e "${GREEN}🚀 READY FOR DEPLOYMENT!${NC}"
    echo -e "${YELLOW}Run './deploy-to-vultr.sh' to deploy the application${NC}"
else
    echo -e "${RED}⚠️  DEPLOYMENT BLOCKED${NC}"
    echo -e "${YELLOW}Please resolve the issues above before deploying${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo "• Start deployment: ./deploy-to-vultr.sh"
echo "• Test after deployment: ./test-deployment.sh"
echo "• Check backend directly: curl http://${BACKEND_IP}:8000/health"
echo "• Access frontend: http://${FRONTEND_IP}:3000"

#!/bin/bash

# Comprehensive deployment script for both frontend and backend updates
# Frontend: 45.32.212.233:3000 → Backend: 149.28.123.26:8000

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

echo -e "${BLUE}🚀 Anna Webinar Demo - Comprehensive Deployment${NC}"
echo -e "${YELLOW}Frontend Target: ${FRONTEND_IP}:3000${NC}"
echo -e "${YELLOW}Backend Target: ${BACKEND_IP}:8000${NC}"
echo ""

# Function to run commands on remote server
run_remote() {
    local server=$1
    local command=$2
    ssh -o StrictHostKeyChecking=no ${VPS_USER}@${server} "$command"
}

# Step 1: Deploy Backend Updates (RAG Pipeline fixes)
echo -e "${BLUE}📡 Step 1: Deploying Backend Updates${NC}"

echo "1. Uploading backend fixes to ${BACKEND_IP}..."
# Copy the fixed RAG pipeline
scp -o StrictHostKeyChecking=no ../src/core/rag_pipeline.py ${VPS_USER}@${BACKEND_IP}:/opt/audio-rag-agent-deploy/core/

echo "2. Restarting backend service..."
run_remote ${BACKEND_IP} "cd /opt/audio-rag-agent-deploy && docker-compose restart"

echo "3. Checking backend health..."
sleep 5
if curl -s http://${BACKEND_IP}:8000/health > /dev/null; then
    echo -e "   ${GREEN}✅ Backend is responding${NC}"
else
    echo -e "   ${YELLOW}⚠️  Backend might still be starting...${NC}"
fi

echo ""

# Step 2: Deploy Frontend Updates
echo -e "${BLUE}🌐 Step 2: Deploying Frontend Updates${NC}"

echo "1. Uploading frontend build to ${FRONTEND_IP}..."
./deploy-to-vultr.sh

echo ""

# Step 3: Final Verification
echo -e "${BLUE}🔍 Step 3: Final Verification${NC}"

echo "1. Testing backend connectivity..."
BACKEND_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://${BACKEND_IP}:8000/health)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo -e "   ${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "   ${RED}❌ Backend health check failed (Status: $BACKEND_STATUS)${NC}"
fi

echo "2. Testing frontend accessibility..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://${FRONTEND_IP}:3000)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "   ${GREEN}✅ Frontend is accessible${NC}"
else
    echo -e "   ${YELLOW}⚠️  Frontend not accessible yet (Status: $FRONTEND_STATUS)${NC}"
fi

echo "3. Testing end-to-end connectivity..."
QUERY_TEST=$(curl -s -X POST http://${BACKEND_IP}:8000/query \
    -H "Content-Type: application/json" \
    -d '{"text":"Hello, are you working?"}' \
    -w '%{http_code}' -o /tmp/query_response.txt)

if [ "$QUERY_TEST" = "200" ]; then
    echo -e "   ${GREEN}✅ Backend query API is working${NC}"
    echo -e "   Response: $(cat /tmp/query_response.txt | head -c 100)..."
else
    echo -e "   ${RED}❌ Backend query test failed (Status: $QUERY_TEST)${NC}"
fi

echo ""

# Final Summary
echo -e "${BLUE}📋 Deployment Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$BACKEND_STATUS" = "200" ] && [ "$FRONTEND_STATUS" = "200" ] && [ "$QUERY_TEST" = "200" ]; then
    echo -e "${GREEN}🎉 DEPLOYMENT SUCCESSFUL!${NC}"
    echo ""
    echo -e "${GREEN}✨ Your Anna Webinar Demo is now live!${NC}"
    echo -e "   🌐 Frontend: http://${FRONTEND_IP}:3000"
    echo -e "   📡 Backend:  http://${BACKEND_IP}:8000"
    echo ""
    echo -e "${BLUE}🧪 Test the application:${NC}"
    echo "   1. Open: http://${FRONTEND_IP}:3000"
    echo "   2. Click 'Play' to start the webinar"
    echo "   3. Open the AI chat and ask questions"
    echo "   4. Test the fixed query functionality"
    
elif [ "$BACKEND_STATUS" = "200" ] && [ "$QUERY_TEST" = "200" ]; then
    echo -e "${YELLOW}⚠️  Backend deployed successfully, frontend may still be loading${NC}"
    echo -e "   Try accessing http://${FRONTEND_IP}:3000 in a few minutes"
    
else
    echo -e "${RED}❌ Some issues detected${NC}"
    echo -e "   Backend Status: $BACKEND_STATUS"
    echo -e "   Frontend Status: $FRONTEND_STATUS"
    echo -e "   Query Test: $QUERY_TEST"
fi

echo ""
echo -e "${BLUE}🔧 Troubleshooting:${NC}"
echo "   • Backend logs: ssh ${VPS_USER}@${BACKEND_IP} 'docker logs audio-rag-agent'"
echo "   • Frontend logs: ssh ${VPS_USER}@${FRONTEND_IP} 'docker logs anna-webinar-demo'"
echo "   • Manual restart: docker-compose restart"

rm -f /tmp/query_response.txt

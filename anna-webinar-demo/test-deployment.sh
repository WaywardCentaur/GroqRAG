#!/bin/bash

# Quick test script for Anna Webinar Demo deployment

VPS_IP="45.32.212.233"
VPS_USER="root"

echo "🧪 Testing Anna Webinar Demo deployment..."

# Test SSH connection
echo "1. Testing SSH connection..."
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${VPS_USER}@${VPS_IP} "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "   ✅ SSH connection successful"
else
    echo "   ❌ SSH connection failed"
    exit 1
fi

# Test if the application is running
echo "2. Testing application availability..."
if ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000" | grep -q "200"; then
    echo "   ✅ Application is responding on port 3000"
else
    echo "   ❌ Application is not responding"
fi

# Test external accessibility
echo "3. Testing external accessibility..."
if curl -s -o /dev/null -w '%{http_code}' http://${VPS_IP}:3000 2>/dev/null | grep -q "200"; then
    echo "   ✅ Application is accessible externally"
else
    echo "   ❌ Application is not accessible externally"
    echo "   💡 Check firewall settings and ensure port 3000 is open"
fi

# Test backend connection (RAG server at 149.28.123.26)
echo "4. Testing backend API connection..."
BACKEND_IP="149.28.123.26"
if curl -s -o /dev/null -w '%{http_code}' http://${BACKEND_IP}:8000/health 2>/dev/null | grep -q "200"; then
    echo "   ✅ Backend API is accessible at ${BACKEND_IP}:8000"
else
    echo "   ⚠️  Backend API is not accessible at ${BACKEND_IP}:8000"
    echo "   💡 Ensure the backend server is running at 149.28.123.26"
fi

# Test WebSocket connection for audio streaming
echo "5. Testing WebSocket audio endpoint..."
if command -v wscat &> /dev/null; then
    if timeout 5s wscat -c ws://${BACKEND_IP}:8000/audio --close 2>/dev/null | grep -q "connected"; then
        echo "   ✅ WebSocket audio endpoint is accessible at ${BACKEND_IP}:8000"
    else
        echo "   ⚠️  WebSocket audio endpoint test inconclusive"
    fi
else
    echo "   ⚠️  wscat not installed, skipping WebSocket test"
    echo "   💡 Install with: npm install -g wscat"
fi

# Test audio streaming capability
echo "6. Testing audio streaming features..."
if ssh ${VPS_USER}@${VPS_IP} "curl -s http://localhost:3000 | grep -q 'audio'" 2>/dev/null; then
    echo "   ✅ Audio streaming features detected in frontend"
else
    echo "   ⚠️  Could not verify audio streaming features"
fi

echo ""
echo "🌐 If all tests pass, your app should be available at:"
echo "   Frontend: http://${VPS_IP}:3000"
echo "   Backend API: http://${VPS_IP}:8000"
echo "   WebSocket Audio: ws://${VPS_IP}:8000/audio"
echo ""
echo "🎤 Audio Streaming Features:"
echo "   - Real-time audio capture from webinar video"
echo "   - Live transcription display"
echo "   - WebSocket connection to RAG backend"
echo "   - Integrated chat with transcribed content"

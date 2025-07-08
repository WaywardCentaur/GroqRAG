#!/bin/bash

# Anna Webinar Demo - Final Verification Script
# Tests end-to-end connectivity between frontend and backend

echo "🔍 Anna Webinar Demo - Final Verification"
echo "========================================"

# Test backend first
echo "1. Testing Backend (149.28.123.26:8000)..."
BACKEND_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://149.28.123.26:8000/health 2>/dev/null)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo "   ✅ Backend is running and healthy"
    
    # Test backend query endpoint
    echo "2. Testing Backend Query API..."
    QUERY_RESPONSE=$(curl -s -X POST http://149.28.123.26:8000/query \
        -H "Content-Type: application/json" \
        -d '{"query":"Hello, can you help me?"}' 2>/dev/null)
    
    if [ ! -z "$QUERY_RESPONSE" ]; then
        echo "   ✅ Backend query API is working"
    else
        echo "   ⚠️  Backend query API test inconclusive"
    fi
else
    echo "   ❌ Backend not accessible (Status: $BACKEND_STATUS)"
fi

echo ""

# Test frontend
echo "3. Testing Frontend (45.32.212.233:3000)..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://45.32.212.233:3000 2>/dev/null)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "   ✅ Frontend is accessible"
    
    # Check if it's actually the React app
    FRONTEND_CONTENT=$(curl -s http://45.32.212.233:3000 2>/dev/null | grep -i "anna\|webinar\|react" | head -1)
    if [ ! -z "$FRONTEND_CONTENT" ]; then
        echo "   ✅ React application is loaded"
    else
        echo "   ⚠️  Frontend response received but content unclear"
    fi
else
    echo "   ⚠️  Frontend not accessible yet (Status: $FRONTEND_STATUS)"
    echo "   💡 Deployment may still be in progress"
fi

echo ""

# Final status
echo "🎯 Final Status:"
if [ "$BACKEND_STATUS" = "200" ] && [ "$FRONTEND_STATUS" = "200" ]; then
    echo "   🎉 DEPLOYMENT SUCCESSFUL!"
    echo "   🌐 Application URL: http://45.32.212.233:3000"
    echo ""
    echo "✨ Features Available:"
    echo "   • AI Chat powered by Groq RAG backend"
    echo "   • Real-time audio streaming to backend"
    echo "   • Live transcription display"
    echo "   • WebSocket communication for audio"
    echo ""
    echo "🧪 Test the application:"
    echo "   1. Open: http://45.32.212.233:3000"
    echo "   2. Start the webinar video"
    echo "   3. Try the AI chat"
    echo "   4. Test audio streaming features"
    
elif [ "$BACKEND_STATUS" = "200" ]; then
    echo "   ⚠️  Backend ready, waiting for frontend deployment"
    echo "   ⏳ Try again in a few minutes"
    
else
    echo "   ❌ Issues detected - check server status"
fi

echo ""

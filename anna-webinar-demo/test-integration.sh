#!/bin/bash

echo "🧪 Testing Anna Webinar Demo - Audio & Video Integration"
echo "======================================================="

FRONTEND_URL="http://45.32.212.233"
BACKEND_URL="http://149.28.123.26"

echo "🏥 Health Check - Backend API..."
curl -s "$BACKEND_URL/health" && echo "✅ Backend is healthy" || echo "❌ Backend is down"

echo ""
echo "🏥 Health Check - Frontend..."
curl -s -I "$FRONTEND_URL" | head -1 && echo "✅ Frontend is responding" || echo "❌ Frontend is down"

echo ""
echo "🧪 Testing API Endpoints..."

echo "📄 Testing document loading:"
curl -s "$BACKEND_URL/documents" | head -100

echo ""
echo "🤖 Testing AI query:"
curl -s -X POST "$BACKEND_URL/query" \
  -H "Content-Type: application/json" \
  -d '{"text": "What is this demo about?"}' | head -200

echo ""
echo "🔌 Testing WebSocket endpoints:"
echo "Audio WebSocket should be available at: ws://149.28.123.26/ws/audio"

echo ""
echo "📺 Frontend Features to Test Manually:"
echo "1. Open $FRONTEND_URL in browser"
echo "2. Click 'Play webinar' - should load YouTube video"
echo "3. Click microphone button - should request mic permissions"
echo "4. Speak into microphone - should see live transcriptions"
echo "5. Type in AI chat - should get responses from backend"
echo "6. Check browser console for WebSocket connection logs"

echo ""
echo "🎤 Audio Streaming Test:"
echo "- Microphone button should turn red when recording"
echo "- Live transcriptions should appear in video overlay"
echo "- Transcriptions should also appear in chat with 🎤 prefix"
echo "- WebSocket connection status shown in chat header"

echo ""
echo "🔍 Debugging Tips:"
echo "- Open browser dev tools (F12)"
echo "- Check Console tab for API/WebSocket logs"
echo "- Check Network tab for failed requests"
echo "- Verify microphone permissions in browser"

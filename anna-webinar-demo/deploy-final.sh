#!/bin/bash

echo "🚀 Deploying Anna Webinar Demo with Full Audio/Video Integration"
echo "================================================"

# Frontend deployment
FRONTEND_SERVER="45.32.212.233"
BACKEND_SERVER="149.28.123.26"

echo "📦 Building production bundle..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Please fix errors before deploying."
    exit 1
fi

echo "✅ Build successful!"

echo "🔗 Deploying to frontend server ($FRONTEND_SERVER)..."

# Deploy to frontend server
scp -r build/* root@$FRONTEND_SERVER:/var/www/html/

if [ $? -eq 0 ]; then
    echo "✅ Frontend deployed successfully!"
    echo ""
    echo "🌐 App is now live at: http://$FRONTEND_SERVER"
    echo "🔧 Backend API: http://$BACKEND_SERVER"
    echo ""
    echo "📝 Features now available:"
    echo "  ✅ YouTube webinar video integration"
    echo "  ✅ Real-time audio streaming"
    echo "  ✅ Live transcription display"
    echo "  ✅ AI chat with RAG backend"
    echo "  ✅ Responsive design"
    echo ""
    echo "🎤 Audio Features:"
    echo "  • Click microphone button to start/stop recording"
    echo "  • Live transcriptions appear in video overlay"
    echo "  • Transcriptions also added to AI chat"
    echo "  • WebSocket connection to backend for real-time audio processing"
    echo ""
    echo "📺 Video Features:"
    echo "  • YouTube webinar auto-plays when started"
    echo "  • Live streaming indicators"
    echo "  • Overlay controls for audio and transcriptions"
    echo ""
    echo "🤖 AI Chat Features:"
    echo "  • Real-time connection status"
    echo "  • Smart error handling"
    echo "  • Audio transcription integration"
    echo "  • RAG-powered responses"
    echo ""
    echo "🔧 Test the deployment:"
    echo "  1. Open http://$FRONTEND_SERVER in browser"
    echo "  2. Click 'Play webinar' to start video"
    echo "  3. Click microphone button to test audio streaming"
    echo "  4. Ask questions in AI chat"
else
    echo "❌ Deployment failed!"
    exit 1
fi

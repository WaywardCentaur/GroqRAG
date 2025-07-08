#!/bin/bash

# Test Audio Streaming Features
# This script helps verify the audio streaming functionality

echo "🎵 Testing Anna Webinar Demo Audio Streaming"
echo "==========================================="

# Check if we're in the right directory
if [ ! -f "src/audioStreamService.js" ]; then
    echo "❌ Audio streaming files not found. Please run from anna-webinar-demo directory."
    exit 1
fi

echo "✅ Audio streaming service found"

# Check if the build was successful
if [ -d "build" ]; then
    echo "✅ Production build exists"
else
    echo "🔨 Building production version..."
    npm run build
fi

echo ""
echo "🎯 Audio Streaming Features Added:"
echo "- 🎤 Real-time audio streaming to RAG backend"
echo "- 📝 Live transcription display"
echo "- 🔄 WebSocket connection for audio data"
echo "- 🎮 Audio control buttons"
echo "- 📱 Responsive audio interface"
echo "- 🔗 Chat integration with transcriptions"

echo ""
echo "🧪 To test audio streaming:"
echo "1. Deploy: ./deploy-simple.sh"
echo "2. Access: http://45.32.212.233:3000"
echo "3. Start webinar (click play)"
echo "4. Enable audio streaming (🎤 button)"
echo "5. Watch for live transcriptions"
echo "6. Ask questions about the audio content"

echo ""
echo "📋 Backend Requirements:"
echo "- WebSocket endpoint: /audio"
echo "- Audio format: PCM 16-bit, 16kHz"
echo "- Real-time transcription capability"

echo ""
echo "🔧 Browser Requirements:"
echo "- Web Audio API support"
echo "- WebSocket support"
echo "- Modern browser (Chrome, Firefox, Safari, Edge)"

echo ""
echo "🚀 Ready to deploy with audio streaming!"

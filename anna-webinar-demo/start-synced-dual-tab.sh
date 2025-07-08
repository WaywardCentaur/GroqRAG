#!/bin/bash
# Start script for the synchronized dual tab system

echo "🚀 Starting Anna Webinar Demo - Synchronized Dual Tab System"
echo "=========================================================="

# Set environment variables
export PORT=3000
export REACT_APP_API_URL=http://149.28.123.26:8000
export REACT_APP_WS_URL=ws://149.28.123.26:8000
export REACT_APP_ENV=development
export BROWSER=none

# Clear cache
echo "🧹 Clearing React cache..."
rm -rf node_modules/.cache

echo ""
echo "📋 Synchronized Dual Tab System Features:"
echo "  ✅ Main tab: YouTube video + AI chat + transcription overlay"
echo "  ✅ Player tab: YouTube video + audio capture (synchronized)"
echo "  ✅ Both videos play simultaneously and in sync"
echo "  ✅ Audio capture from player tab only"
echo "  ✅ Transcriptions appear on both tabs"
echo "  ✅ Clean separation: chat only in main tab"
echo ""

echo "🎬 How it works:"
echo "  1. Click 'Start Video' in main tab"
echo "  2. Video starts playing in main tab"
echo "  3. Player tab opens automatically with synchronized video"
echo "  4. In player tab: Click 'Start Audio Capture' for transcription"
echo "  5. Chat with Anna AI in main tab while videos play in sync"
echo ""

echo "🌐 Starting React app on http://localhost:3000"
echo "📱 Player tab will open automatically when you start the video"
echo ""

# Start the app
npm start

#!/bin/bash
# Start script for the new dual tab system

echo "🚀 Starting Anna Webinar Demo - Dual Tab System"
echo "=============================================="

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
echo "📋 Dual Tab System Features:"
echo "  - Main tab: Video player + AI chat"
echo "  - Player tab: YouTube video + audio capture (NO CHAT)"
echo "  - Clean separation of concerns"
echo "  - Robust error handling"
echo ""

echo "🌐 Starting React app on http://localhost:3000"
echo "📱 Player tab will open automatically when you start the video"
echo ""

# Start the app
npm start

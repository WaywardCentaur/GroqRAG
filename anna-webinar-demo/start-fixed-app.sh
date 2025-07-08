#!/bin/bash
# Script to start the React app with proper environment settings

# Set environment variables explicitly
export PORT=3000
export REACT_APP_API_URL=http://149.28.123.26:8000
export REACT_APP_WS_URL=ws://149.28.123.26:8000
export REACT_APP_ENV=development
export BROWSER=none

# Clear any cached data that might be causing issues
echo "Clearing React cache..."
rm -rf node_modules/.cache

# Start React app
echo "Starting React app on port 3000..."
npm start

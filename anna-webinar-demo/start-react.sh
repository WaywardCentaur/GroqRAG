#!/bin/bash
# Script to start the React app on port 3000

echo "🚀 Starting Anna Webinar Demo React App on port 3000..."

# Check if PORT is already set in .env file
if grep -q "PORT=3000" .env 2>/dev/null; then
  echo "✅ PORT already set to 3000 in .env"
else
  # Create or append to .env file
  echo "PORT=3000" >> .env
  echo "✅ Added PORT=3000 to .env file"
fi

# Make sure we have REACT_APP_API_URL set
if ! grep -q "REACT_APP_API_URL" .env 2>/dev/null; then
  echo "REACT_APP_API_URL=http://localhost:8000" >> .env
  echo "✅ Added REACT_APP_API_URL=http://localhost:8000 to .env file"
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "❌ Error: npm could not be found. Please install Node.js and npm."
  exit 1
fi

# Clear any processes using port 3000
echo "🧹 Clearing port 3000 if in use..."
lsof -i :3000 | grep LISTEN | awk '{print $2}' | xargs kill -9 2>/dev/null || true

# Start the React app
echo "🚀 Starting React development server..."
echo "📝 Once started, open: http://localhost:3000 in your browser"
echo "-----------------------------------------------------------"
PORT=3000 npm start

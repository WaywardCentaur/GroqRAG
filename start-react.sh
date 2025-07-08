#!/bin/bash

# Check if a specific port is provided, otherwise use 3000
PORT="${1:-3000}"

# Kill any processes running on the specified port
echo "🔍 Checking if port $PORT is in use..."
PID=$(lsof -i :$PORT -t)
if [ ! -z "$PID" ]; then
    echo "🛑 Stopping process on port $PORT (PID: $PID)"
    kill -9 $PID
fi

# Start React app on specified port
echo "🚀 Starting React app on port $PORT"
echo "📝 Access the app at: http://localhost:$PORT"
echo "---------------------------------------"

cd "/Users/raymondmauge/Groq RAG/GroqRAG/anna-webinar-demo" && PORT=$PORT npm start

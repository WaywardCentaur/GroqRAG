#!/bin/bash

# Check if .env file exists, if not create from example
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit .env file with your actual configuration values."
    exit 1
fi

# Create necessary directories
mkdir -p debug_audio
mkdir -p data/chromadb

# Make sure debug_audio directory exists
mkdir -p debug_audio

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit .env and add your Groq API key"
    exit 1
fi

# Build and start the containers
docker-compose up --build -d

echo "Containers are starting..."
echo "Web app will be available at http://localhost:8000"
echo "ChromaDB will be available at http://localhost:8001"

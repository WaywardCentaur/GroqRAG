#!/bin/bash

# Quick Deployment Script for Vultr Server: 149.28.123.26
# This script helps you deploy the Audio RAG Agent to your specific Vultr server

set -e

SERVER_IP="149.28.123.26"
SERVER_USER="root"
SERVER_PASSWORD="3Ax}5s#2Uya#VA?]"
DEPLOY_DIR="/opt/audio-rag-agent"

echo "🚀 Deploying Audio RAG Agent to $SERVER_IP..."

# Function to check if we can connect to the server
check_connection() {
    echo "🔍 Checking connection to $SERVER_IP..."
    if ping -c 1 $SERVER_IP >/dev/null 2>&1; then
        echo "✅ Server is reachable"
    else
        echo "❌ Cannot reach server. Please check the IP address and your connection."
        exit 1
    fi
}

# Function to upload files to server
upload_files() {
    echo "📤 Uploading files to server..."
    
    # Create deployment package
    if [ ! -f "audio-rag-agent-vultr.tar.gz" ]; then
        echo "📦 Creating deployment package..."
        ./create-deploy-package.sh
    fi
    
    # Upload the package
    echo "🔄 Uploading package to server..."
    scp audio-rag-agent-vultr.tar.gz $SERVER_USER@$SERVER_IP:/tmp/
    
    echo "✅ Files uploaded successfully"
}

# Function to deploy on server
deploy_on_server() {
    echo "🏗️  Deploying on server..."
    
    ssh $SERVER_USER@$SERVER_IP << 'EOF'
        set -e
        
        # Extract the package
        cd /tmp
        tar -xzf audio-rag-agent-vultr.tar.gz
        
        # Move to deployment directory
        mkdir -p /opt
        mv audio-rag-agent-deploy /opt/audio-rag-agent
        chown -R root:root /opt/audio-rag-agent
        
        # Enter deployment directory
        cd /opt/audio-rag-agent
        
        # Setup environment
        cp .env.production .env
        
        echo "⚠️  IMPORTANT: You need to edit the .env file with your GROQ_API_KEY"
        echo "   The .env file has been created with your server IP pre-configured"
        echo "   You just need to add your GROQ_API_KEY"
        
        # Make scripts executable
        chmod +x *.sh
        
        echo "✅ Files deployed to /opt/audio-rag-agent"
        echo "📋 Next steps:"
        echo "   1. Edit .env with your GROQ_API_KEY"
        echo "   2. Run deployment: ./deploy-vultr.sh"
        echo "   3. Access your app at: http://149.28.123.26"
EOF
}

# Function to show deployment status
show_status() {
    echo ""
    echo "📊 Deployment Information:"
    echo "   Server IP: $SERVER_IP"
    echo "   Web Interface: http://$SERVER_IP"
    echo "   API Endpoint: http://$SERVER_IP:8000"
    echo "   Health Check: http://$SERVER_IP:8000/health"
    echo ""
    echo "🔧 Server Management:"
    echo "   SSH Access: ssh $SERVER_USER@$SERVER_IP"
    echo "   App Directory: $DEPLOY_DIR"
    echo "   Logs: docker-compose logs"
    echo "   Restart: sudo systemctl restart audio-rag-agent"
    echo ""
}

# Main deployment flow
main() {
    echo "🎯 Audio RAG Agent - Vultr Deployment"
    echo "======================================"
    
    check_connection
    
    read -p "🚀 Ready to deploy to $SERVER_IP? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    upload_files
    deploy_on_server
    show_status
    
    echo "🎉 Deployment completed!"
    echo "   Next: SSH to your server and complete the setup:"
    echo "   ssh $SERVER_USER@$SERVER_IP"
    echo "   cd $DEPLOY_DIR"
    echo "   nano .env  # Add your GROQ_API_KEY"
    echo "   ./deploy-vultr.sh"
}

# Check if required files exist
if [ ! -f "deploy-vultr.sh" ] || [ ! -f "create-deploy-package.sh" ]; then
    echo "❌ Required deployment files not found."
    echo "   Please run this script from the project root directory."
    exit 1
fi

# Run main function
main

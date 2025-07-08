#!/bin/bash

# Vultr Deployment Script for Audio RAG Agent
# This script sets up and deploys the Audio RAG Agent on a Vultr server

set -e  # Exit on any error

echo "🚀 Starting Audio RAG Agent deployment on Vultr..."

# Update system packages
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    # Add current user to docker group (if not root)
    if [ "$USER" != "root" ]; then
        usermod -aG docker $USER
    fi
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Install nginx for reverse proxy
echo "🌐 Installing Nginx..."
apt-get install -y nginx certbot python3-certbot-nginx

# Create application directory
APP_DIR="/opt/audio-rag-agent"
mkdir -p $APP_DIR
# Set ownership based on current user
if [ "$USER" != "root" ]; then
    chown $USER:$USER $APP_DIR
fi

# Clone or copy application files (assuming files are already present)
cd $APP_DIR

# Set up environment variables
echo "⚙️ Setting up environment variables..."
if [ ! -f .env ]; then
    cp .env.production .env
    echo "Please edit .env file with your actual configuration:"
    echo "  - Set your GROQ_API_KEY"
    echo "  - Configure other settings as needed"
    read -p "Press Enter after editing .env file..."
fi

# Create necessary directories
mkdir -p data/chromadb
mkdir -p debug_audio
mkdir -p logs

# Set permissions
chmod 755 data debug_audio logs
chmod 644 .env

# Build and start the application
echo "🏗️ Building and starting the application..."
docker-compose build
docker-compose up -d

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 30

# Test health endpoint
echo "🔍 Testing application health..."
if curl -f http://localhost:8000/health; then
    echo "✅ Application is healthy!"
else
    echo "❌ Application health check failed"
    docker-compose logs
    exit 1
fi

# Configure Nginx
echo "🌐 Configuring Nginx reverse proxy..."
tee /etc/nginx/sites-available/audio-rag-agent > /dev/null <<EOF
server {
    listen 80;
    server_name 149.28.123.26;  # Your Vultr server IP
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    
    location / {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint (allow without rate limiting)
    location /health {
        proxy_pass http://localhost:8000/health;
        proxy_set_header Host \$host;
        access_log off;
    }
    
    # Static files caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/audio-rag-agent /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Start Nginx
systemctl enable nginx
systemctl restart nginx

# Set up systemd service for auto-restart
echo "🔄 Setting up systemd service..."
tee /etc/systemd/system/audio-rag-agent.service > /dev/null <<EOF
[Unit]
Description=Audio RAG Agent
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable audio-rag-agent.service

# Set up log rotation
echo "📝 Setting up log rotation..."
tee /etc/logrotate.d/audio-rag-agent > /dev/null <<EOF
$APP_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f $APP_DIR/docker-compose.yml restart app
    endscript
}
EOF

# Set up firewall
echo "🔥 Configuring firewall..."
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Your server is now accessible at: http://149.28.123.26"
echo "2. If you have a domain, point it to 149.28.123.26"
echo "3. Edit /etc/nginx/sites-available/audio-rag-agent and replace the server_name if using a domain"
echo "4. Restart Nginx: sudo systemctl restart nginx"
echo "5. Set up SSL certificate if using a domain: sudo certbot --nginx -d your-domain.com"
echo "6. Test your deployment at http://149.28.123.26"
echo ""
echo "📊 Useful commands:"
echo "  - Check application logs: docker-compose -f $APP_DIR/docker-compose.yml logs"
echo "  - Restart application: sudo systemctl restart audio-rag-agent"
echo "  - Check health: curl http://149.28.123.26:8000/health"
echo "  - Access web interface: http://149.28.123.26"
echo "  - Monitor with htop: sudo apt install htop && htop"

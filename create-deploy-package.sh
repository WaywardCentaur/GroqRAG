#!/bin/bash

# Vultr Deployment Package Creator
# Creates a clean deployment package for Vultr servers

set -e

echo "📦 Creating Vultr deployment package..."

# Create deployment directory
DEPLOY_DIR="audio-rag-agent-deploy"
mkdir -p $DEPLOY_DIR

echo "📁 Copying application files..."

# Copy core application files
cp -r src/ $DEPLOY_DIR/
cp -r static/ $DEPLOY_DIR/
cp requirements.txt $DEPLOY_DIR/
cp Dockerfile $DEPLOY_DIR/
cp docker-compose.yml $DEPLOY_DIR/

# Copy configuration files
cp .env.production $DEPLOY_DIR/
echo "⚠️  Remember to rename .env.production to .env and configure with your actual values!"

# Copy deployment scripts
cp deploy-vultr.sh $DEPLOY_DIR/
cp monitor.sh $DEPLOY_DIR/
cp backup.sh $DEPLOY_DIR/
cp verify-deployment.sh $DEPLOY_DIR/

# Copy documentation
cp README.md $DEPLOY_DIR/
cp DEPLOYMENT-CHECKLIST.md $DEPLOY_DIR/
cp DEPLOYMENT.md $DEPLOY_DIR/

# Make scripts executable
chmod +x $DEPLOY_DIR/*.sh

# Create data directories
mkdir -p $DEPLOY_DIR/data/chromadb
mkdir -p $DEPLOY_DIR/debug_audio
mkdir -p $DEPLOY_DIR/logs

# Create .gitignore for deployment
cat > $DEPLOY_DIR/.gitignore << EOF
# Environment variables
.env

# Data directories
data/chromadb/*
debug_audio/*
logs/*

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

# Create deployment instructions
cat > $DEPLOY_DIR/DEPLOY-README.md << EOF
# Audio RAG Agent - Vultr Deployment Package

This package contains everything needed to deploy the Audio RAG Agent on Vultr.

## Quick Deployment Steps

1. **Upload to Server**: Upload this entire directory to your Vultr server
2. **Configure Environment**: 
   \`\`\`bash
   cp .env.production .env
   nano .env  # Edit with your actual values (especially GROQ_API_KEY)
   \`\`\`
3. **Deploy**: 
   \`\`\`bash
   chmod +x deploy-vultr.sh
   ./deploy-vultr.sh
   \`\`\`
4. **Verify**: Follow the DEPLOYMENT-CHECKLIST.md for complete setup

## What's Included

- ✅ Complete application source code
- ✅ Docker configuration for containerization
- ✅ Nginx reverse proxy configuration
- ✅ SSL/HTTPS setup scripts
- ✅ Monitoring and backup scripts
- ✅ Automated deployment script
- ✅ Comprehensive documentation

## Requirements

- Vultr VPS with minimum 2GB RAM, 50GB disk
- Ubuntu 20.04+ or similar Linux distribution
- Domain name (optional, for SSL)

## Support

See DEPLOYMENT-CHECKLIST.md for detailed instructions and troubleshooting.
EOF

# Create tar archive
echo "🗜️  Creating deployment archive..."
tar -czf audio-rag-agent-vultr.tar.gz $DEPLOY_DIR/

# Calculate file sizes
PACKAGE_SIZE=$(du -sh $DEPLOY_DIR | cut -f1)
ARCHIVE_SIZE=$(du -sh audio-rag-agent-vultr.tar.gz | cut -f1)

echo ""
echo "✅ Deployment package created successfully!"
echo ""
echo "📊 Package Details:"
echo "   Directory: $DEPLOY_DIR/ ($PACKAGE_SIZE)"
echo "   Archive: audio-rag-agent-vultr.tar.gz ($ARCHIVE_SIZE)"
echo ""
echo "📤 Upload Instructions:"
echo "1. Upload audio-rag-agent-vultr.tar.gz to your Vultr server"
echo "2. Extract: tar -xzf audio-rag-agent-vultr.tar.gz"
echo "3. Enter directory: cd $DEPLOY_DIR"
echo "4. Follow the DEPLOY-README.md instructions"
echo ""
echo "🌟 Ready for Vultr deployment!"

# Clean up directory (keep only the archive)
read -p "Remove deployment directory and keep only the archive? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf $DEPLOY_DIR
    echo "🧹 Cleaned up. Only audio-rag-agent-vultr.tar.gz remains."
fi

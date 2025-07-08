# Audio RAG Agent - Vultr Deployment Package

This package contains everything needed to deploy the Audio RAG Agent on Vultr.

## Quick Deployment Steps

1. **Upload to Server**: Upload this entire directory to your Vultr server
2. **Configure Environment**: 
   ```bash
   cp .env.production .env
   nano .env  # Edit with your actual values (especially GROQ_API_KEY)
   ```
3. **Deploy**: 
   ```bash
   chmod +x deploy-vultr.sh
   ./deploy-vultr.sh
   ```
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

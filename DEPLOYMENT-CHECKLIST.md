# Pre-Deployment Checklist

## ✅ Files Ready for Deployment

### Core Application Files
- [x] `src/` - Main application code
- [x] `static/` - Static web files with document/transcription management UI
- [x] `requirements.txt` - Python dependencies
- [x] `Dockerfile` - Container configuration
- [x] `docker-compose.yml` - Multi-container setup

### Web UI Features
- [x] Document upload interface
- [x] Documents table with delete functionality
- [x] Transcriptions table with delete functionality
- [x] Real-time audio recording and transcription
- [x] Query interface for RAG system
- [x] Responsive design for mobile/desktop

### Configuration Files
- [x] `.env.production` - Production environment template
- [x] `DEPLOYMENT.md` - Comprehensive deployment guide

### Deployment Scripts
- [x] `deploy-vultr.sh` - Automated deployment script
- [x] `monitor.sh` - Production monitoring script
- [x] `backup.sh` - Data backup script

### API Endpoints Ready
- [x] `/health` - Health check for load balancers
- [x] `/debug/context` - Context inspection
- [x] `/debug/stats` - Performance statistics
- [x] `/debug/clear-*` - Context management
- [x] `/query` - Main RAG endpoint
- [x] `/documents` - Document upload and management
- [x] `GET /documents` - List all documents
- [x] `DELETE /documents/{document_id}` - Delete specific document
- [x] `/transcriptions` - Transcription management
- [x] `GET /transcriptions` - List all transcriptions
- [x] `DELETE /transcriptions/{transcription_id}` - Delete specific transcription
- [x] `/audio` - WebSocket audio stream

## 🚀 Deployment Steps

### 1. Server Setup
- [ ] Create Vultr VPS instance (min 2GB RAM)
- [ ] Configure SSH access
- [ ] Point domain to server IP (optional)

### 2. Application Deployment
- [ ] Upload application files to server
- [ ] Run `./deploy-vultr.sh`
- [ ] Configure `.env` with your settings
- [ ] Set `GROQ_API_KEY`

### 3. Security Configuration
- [ ] Set up firewall rules
- [ ] Configure Nginx reverse proxy
- [ ] Install SSL certificate (if using domain)
- [ ] Test rate limiting

### 4. Production Testing
- [ ] Test health endpoint: `curl http://149.28.123.26:8000/health`
- [ ] Test API endpoint: `curl -X POST 149.28.123.26:8000/query`
- [ ] Test web interface: Visit http://149.28.123.26
- [ ] Test document upload: Upload PDF/TXT files via web UI
- [ ] Test document listing: Check documents table in web UI
- [ ] Test document deletion: Delete documents via web UI
- [ ] Test transcription listing: Check transcriptions table in web UI
- [ ] Test transcription deletion: Delete transcriptions via web UI
- [ ] Test WebSocket connection
- [ ] Verify audio transcription works
- [ ] Test context management endpoints

### 5. Monitoring Setup
- [ ] Add monitoring cron job: `*/5 * * * * /opt/audio-rag-agent/monitor.sh monitor`
- [ ] Set up log rotation
- [ ] Configure backup schedule: `0 2 * * * /opt/audio-rag-agent/backup.sh`
- [ ] Test alert notifications

### 6. Performance Optimization
- [ ] Monitor resource usage
- [ ] Adjust Docker resource limits if needed
- [ ] Configure CDN for static files (optional)
- [ ] Set up database optimization

## 🔧 Configuration Checklist

### Environment Variables (.env)
```bash
GROQ_API_KEY=your_actual_key_here
HOST=0.0.0.0
PORT=8000
ENVIRONMENT=production
WORKERS=4
LOG_LEVEL=INFO
CORS_ORIGINS=http://149.28.123.26,https://149.28.123.26,*
CHROMADB_PERSIST_DIR=./data/chromadb
CACHE_TTL=3600
MAX_CACHE_SIZE=1000
SERVER_IP=149.28.123.26
```

### Required Ports
- [ ] Port 22 (SSH) - open for management
- [ ] Port 80 (HTTP) - open for web traffic
- [ ] Port 443 (HTTPS) - open for secure web traffic
- [ ] Port 8000 - internal (proxied through Nginx)

### File Permissions
- [ ] Application files: `755`
- [ ] Scripts: `755` (executable)
- [ ] Config files: `644`
- [ ] Data directories: `755`

## 📊 Post-Deployment Verification

### Health Checks
```bash
# Basic health
curl http://149.28.123.26:8000/health

# API functionality
curl -X POST "http://149.28.123.26:8000/query" \
     -H "Content-Type: application/json" \
     -d '{"text": "test question"}'

# Document management
curl http://149.28.123.26:8000/documents

# Transcription management
curl http://149.28.123.26:8000/transcriptions

# Context management
curl http://149.28.123.26:8000/debug/stats
```

### Performance Tests
```bash
# Memory usage
free -h

# Disk usage
df -h

# Container status
docker ps

# Application logs
docker-compose logs app
```

### Security Verification
```bash
# Check firewall
sudo ufw status

# Check SSL (if configured)
curl -I https://yourdomain.com

# Check Nginx configuration
sudo nginx -t
```

## 🛠️ Useful Commands

### Application Management
```bash
# Check status
./monitor.sh status

# View logs
./monitor.sh logs

# Restart application
./monitor.sh restart

# Get statistics
./monitor.sh stats
```

### Docker Management
```bash
# View containers
docker-compose ps

# Restart containers
docker-compose restart

# Update containers
docker-compose pull && docker-compose up -d
```

### System Maintenance
```bash
# Update system
sudo apt update && sudo apt upgrade

# Clean Docker
docker system prune -f

# Check disk space
df -h

# Check memory
free -h
```

## 🚨 Troubleshooting

### Common Issues
1. **Port 8000 blocked** - Check firewall rules
2. **Out of memory** - Increase server size or optimize
3. **SSL issues** - Verify domain DNS and certificates
4. **Audio not working** - Check browser permissions
5. **API errors** - Check Groq API key and logs

### Emergency Contacts
- Vultr Support: [support link]
- Application logs: `/opt/audio-rag-agent/logs/`
- System logs: `/var/log/syslog`

## ✅ Go-Live Checklist

- [ ] All health checks passing
- [ ] SSL certificate installed (if using domain)
- [ ] Monitoring and alerts configured
- [ ] Backup system tested
- [ ] Performance benchmarks established
- [ ] Documentation updated
- [ ] Team notified of new deployment

**Ready for production! 🎉**

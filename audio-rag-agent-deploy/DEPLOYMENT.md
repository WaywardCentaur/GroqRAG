# Audio RAG Agent - Vultr Deployment Guide

This guide will help you deploy the Audio RAG Agent on Vultr's cloud infrastructure.

## Prerequisites

- Vultr account with a VPS instance (minimum 2GB RAM, 1 CPU)
- Domain name (optional but recommended)
- Groq API key

## Server Requirements

### Minimum Specifications
- **CPU**: 1 vCPU
- **RAM**: 2GB
- **Storage**: 25GB SSD
- **OS**: Ubuntu 20.04 LTS or 22.04 LTS

### Recommended Specifications
- **CPU**: 2 vCPU
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **OS**: Ubuntu 22.04 LTS

## Quick Deployment

### Step 1: Create Vultr Instance

1. Log into your Vultr account
2. Deploy a new instance:
   - Choose a location near your users
   - Select Ubuntu 22.04 LTS
   - Choose instance size (minimum 2GB RAM)
   - Add your SSH key
   - Deploy the instance

### Step 2: Connect to Your Server

```bash
ssh root@your-server-ip
```

### Step 3: Upload Application Files

```bash
# On your local machine
scp -r /path/to/groq-rag root@your-server-ip:/opt/
```

Or clone from repository:
```bash
# On the server
cd /opt
git clone https://github.com/your-repo/audio-rag-agent.git
cd audio-rag-agent
```

### Step 4: Run Deployment Script

```bash
cd /opt/audio-rag-agent
chmod +x deploy-vultr.sh
./deploy-vultr.sh
```

### Step 5: Configure Environment

Edit the environment file:
```bash
nano .env
```

Set your configuration:
```env
GROQ_API_KEY=your_actual_groq_api_key_here
HOST=0.0.0.0
PORT=8000
ENVIRONMENT=production
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Step 6: Start the Application

```bash
docker-compose up -d
```

## Domain Configuration (Optional)

### Step 1: Configure DNS
Point your domain's A record to your Vultr server's IP address.

### Step 2: Update Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/audio-rag-agent
```

Replace `your-domain.com` with your actual domain.

### Step 3: Get SSL Certificate
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Step 4: Restart Nginx
```bash
sudo systemctl restart nginx
```

## Testing Your Deployment

### Health Check
```bash
curl http://your-server-ip:8000/health
# or
curl https://yourdomain.com/health
```

### API Test
```bash
curl -X POST "http://your-server-ip:8000/query" \
     -H "Content-Type: application/json" \
     -d '{"text": "Hello, how are you?"}'
```

### WebSocket Test
Open your browser and navigate to:
- `http://your-server-ip:8000` (direct access)
- `https://yourdomain.com` (with domain)

## Monitoring and Maintenance

### Check Application Status
```bash
cd /opt/audio-rag-agent
./monitor.sh status
```

### View Logs
```bash
./monitor.sh logs
```

### Get Statistics
```bash
./monitor.sh stats
```

### Restart Application
```bash
./monitor.sh restart
```

### Set Up Automated Monitoring
Add to crontab for regular health checks:
```bash
sudo crontab -e
```

Add this line:
```
*/5 * * * * /opt/audio-rag-agent/monitor.sh monitor
```

## Performance Optimization

### Enable Docker Swarm (for scaling)
```bash
docker swarm init
docker stack deploy -c docker-compose.yml audio-rag
```

### Database Optimization
For high-traffic scenarios, consider using external ChromaDB:
```yaml
# In docker-compose.yml
services:
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8001:8000"
    volumes:
      - chromadb_data:/chroma/chroma
```

### CDN Integration
For static files, consider using Vultr's CDN or Cloudflare.

## Security Configuration

### Firewall Rules
```bash
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### API Rate Limiting
Configure rate limiting in Nginx (already included in deployment script).

### Environment Security
- Never commit `.env` files to version control
- Use strong passwords
- Keep system packages updated
- Monitor access logs regularly

## Backup Strategy

### Database Backup
```bash
# Create backup script
cat > /opt/backup-chromadb.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf /opt/backups/chromadb_$DATE.tar.gz /opt/audio-rag-agent/data/chromadb
find /opt/backups -name "chromadb_*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/backup-chromadb.sh

# Add to crontab
echo "0 2 * * * /opt/backup-chromadb.sh" | sudo crontab -
```

### Configuration Backup
```bash
cp .env .env.backup
cp docker-compose.yml docker-compose.yml.backup
```

## Troubleshooting

### Common Issues

1. **Application won't start**
   ```bash
   docker-compose logs app
   ```

2. **High memory usage**
   ```bash
   docker stats
   ```

3. **Disk space issues**
   ```bash
   df -h
   docker system prune -f
   ```

4. **Network connectivity**
   ```bash
   netstat -tulpn | grep 8000
   ```

### Emergency Recovery
```bash
# Stop everything
docker-compose down

# Reset containers
docker system prune -a -f

# Restart from backup
cp .env.backup .env
docker-compose up -d
```

## Support and Updates

### Updating the Application
```bash
cd /opt/audio-rag-agent
git pull origin main
docker-compose build --no-cache
docker-compose up -d
```

### Log Files Locations
- Application logs: `/opt/audio-rag-agent/logs/`
- Nginx logs: `/var/log/nginx/`
- System logs: `/var/log/syslog`

### Contact Information
For support, check the project repository or documentation.

## Cost Optimization

### Vultr Instance Sizing
- **Development**: $6/month (1GB RAM)
- **Small Production**: $12/month (2GB RAM)
- **Medium Production**: $24/month (4GB RAM)
- **High Traffic**: $48/month (8GB RAM)

### Resource Monitoring
Monitor your usage to optimize costs:
```bash
# CPU usage
top
# Memory usage
free -h
# Disk usage
df -h
# Network usage
iftop
```

## Next Steps

1. Set up monitoring and alerting
2. Configure automated backups
3. Implement log analysis
4. Scale based on traffic patterns
5. Add additional security measures
6. Optimize for your specific use case

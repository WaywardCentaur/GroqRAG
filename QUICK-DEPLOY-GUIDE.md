# Quick Deployment Guide for 149.28.123.26

## 🔐 Server Credentials
- **IP**: 149.28.123.26
- **Username**: root
- **Password**: 3Ax}5s#2Uya#VA?]

## 🚀 Deployment Steps

### Step 1: Run Automated Deployment
From your local machine, run:
```bash
./deploy-to-vultr.sh
```

This will:
- ✅ Check server connectivity
- ✅ Create deployment package
- ✅ Upload files to your server
- ✅ Extract and prepare files

### Step 2: SSH to Server and Complete Setup
```bash
ssh root@149.28.123.26
# Enter password: 3Ax}5s#2Uya#VA?]

cd /opt/audio-rag-agent
```

### Step 3: Configure Environment
```bash
nano .env
```

Add your GROQ API key:
```bash
GROQ_API_KEY=your_actual_groq_api_key_here
```

Save and exit (Ctrl+X, Y, Enter)

### Step 4: Deploy Application
```bash
./deploy-vultr.sh
```

This will:
- ✅ Install Docker and Docker Compose
- ✅ Install and configure Nginx
- ✅ Build and start your application
- ✅ Configure firewall and systemd service
- ✅ Set up monitoring and backups

## 🌐 Access Your Application

After deployment completes:
- **Web Interface**: http://149.28.123.26
- **API Health Check**: http://149.28.123.26:8000/health
- **API Documentation**: http://149.28.123.26:8000/docs

## 🔧 Useful Commands on Server

```bash
# Check application status
docker-compose ps

# View application logs
docker-compose logs -f

# Restart application
systemctl restart audio-rag-agent

# Check Nginx status
systemctl status nginx

# View Nginx logs
tail -f /var/log/nginx/access.log
```

## 🎯 Expected Results

After successful deployment:
1. ✅ Application running on port 8000
2. ✅ Nginx reverse proxy on port 80
3. ✅ Web UI accessible at http://149.28.123.26
4. ✅ Document upload/management working
5. ✅ Audio recording/transcription working
6. ✅ RAG queries working

## 🛠️ Troubleshooting

If something goes wrong:

### Check Docker containers
```bash
docker-compose ps
docker-compose logs
```

### Check Nginx configuration
```bash
nginx -t
systemctl status nginx
```

### Restart everything
```bash
systemctl restart audio-rag-agent
systemctl restart nginx
```

### Check firewall
```bash
ufw status
```

## 🔒 Security Note

Your server is configured with:
- ✅ UFW firewall (ports 22, 80, 443 open)
- ✅ Nginx rate limiting
- ✅ Security headers
- ✅ Non-root container execution

**Remember**: Change the root password after deployment for better security!

## 📞 Support

If you encounter issues:
1. Check the deployment logs
2. Verify your GROQ_API_KEY is correct
3. Ensure all services are running
4. Check firewall settings

Your Audio RAG Agent should be fully operational after following these steps! 🎉

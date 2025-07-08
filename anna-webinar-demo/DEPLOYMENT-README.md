# Anna Webinar Demo - React Frontend

A modern React application that provides an interactive webinar experience with AI-powered chat assistance, connected to the Groq RAG backend.

## 🌟 Features

- **Interactive Webinar Interface**: Clean, modern UI for video webinars
- **AI Chat Assistant**: Real-time chat with RAG-powered AI responses
- **Responsive Design**: Works on desktop and mobile devices
- **Real-time Status**: Connection status indicator for backend health
- **Loading States**: Smooth UX with loading indicators
- **Error Handling**: Graceful error handling and user feedback

## 🚀 Quick Deployment to Vultr VPS

### Prerequisites

1. **Vultr VPS** at `45.32.212.233` with root access
2. **SSH key** configured for passwordless access
3. **Docker** installed locally (for building)

### One-Command Deployment

```bash
./deploy-to-vultr.sh
```

This script will:
- ✅ Install Docker on the VPS
- ✅ Build and deploy the React app
- ✅ Configure firewall settings
- ✅ Start the application in production mode
- ✅ Provide health checks and status

### Testing the Deployment

```bash
./test-deployment.sh
```

## 🔧 Manual Setup

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start development server:**
   ```bash
   npm start
   ```

3. **Access locally:**
   Open [http://localhost:3000](http://localhost:3000)

### Environment Configuration

The app uses environment variables for API endpoints:

- **Development**: `.env.development`
  ```
  REACT_APP_API_URL=http://localhost:8000
  REACT_APP_WS_URL=ws://localhost:8000
  ```

- **Production**: `.env.production`
  ```
  REACT_APP_API_URL=http://45.32.212.233:8000
  REACT_APP_WS_URL=ws://45.32.212.233:8000
  ```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │───▶│   RAG Backend   │───▶│   Groq API      │
│ (Port 3000)     │    │ (Port 8000)     │    │                 │
│                 │    │                 │    │                 │
│ - Video UI      │    │ - FastAPI       │    │ - LLM           │
│ - Chat Interface│    │ - ChromaDB      │    │ - Embeddings    │
│ - Status Monitor│    │ - Audio Process │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📡 API Integration

The frontend connects to these backend endpoints:

- `POST /query` - Send chat messages to AI
- `GET /health` - Check backend status
- `POST /documents` - Upload documents (admin)
- `GET /transcriptions` - Get audio transcriptions
- `WS /audio` - Real-time audio processing

## 🔒 Security Features

- **CORS** configured for frontend domain
- **Input validation** on all forms
- **XSS protection** with Content Security Policy
- **Rate limiting** through backend
- **Secure headers** via nginx

## 🚀 Production Features

### Docker Configuration
- Multi-stage build for optimized images
- Nginx reverse proxy
- Production environment variables
- Health checks and restart policies

### Performance Optimizations
- Asset compression (gzip)
- Static file caching
- Bundle optimization
- Lazy loading for components

## 📊 Monitoring & Logs

### View Application Logs
```bash
ssh root@45.32.212.233 'cd /opt/anna-webinar-demo && docker-compose logs -f'
```

### Check Application Status
```bash
ssh root@45.32.212.233 'cd /opt/anna-webinar-demo && docker-compose ps'
```

### Restart Application
```bash
ssh root@45.32.212.233 'cd /opt/anna-webinar-demo && docker-compose restart'
```

## 🔧 Troubleshooting

### Common Issues

1. **"Connection Failed" Status**
   - Check if RAG backend is running on port 8000
   - Verify firewall allows port 8000
   - Check API URL configuration

2. **Application Not Loading**
   - Verify port 3000 is open
   - Check Docker container status
   - Review nginx configuration

3. **AI Not Responding**
   - Check backend health endpoint
   - Verify Groq API keys in backend
   - Check ChromaDB connection

### Debug Commands

```bash
# Check if ports are open
ssh root@45.32.212.233 'netstat -tlnp | grep -E ":(3000|8000)"'

# Check Docker containers
ssh root@45.32.212.233 'docker ps'

# Check firewall status
ssh root@45.32.212.233 'ufw status'

# Test backend directly
curl http://45.32.212.233:8000/health
```

## 🌐 Access URLs

After successful deployment:

- **Frontend Application**: http://45.32.212.233:3000
- **Backend API**: http://45.32.212.233:8000
- **API Documentation**: http://45.32.212.233:8000/docs

## 🔄 Updates & Maintenance

### Deploy Updates
```bash
# From the anna-webinar-demo directory
./deploy-to-vultr.sh
```

### Backup Configuration
```bash
# Backup deployment files
ssh root@45.32.212.233 'cd /opt && tar -czf anna-webinar-backup-$(date +%Y%m%d).tar.gz anna-webinar-demo'
```

## 📝 Configuration Files

- `Dockerfile` - Multi-stage build configuration
- `docker-compose.yml` - Container orchestration
- `nginx.conf` - Web server configuration
- `.env.production` - Production environment variables
- `deploy-to-vultr.sh` - Automated deployment script

## 🎯 Next Steps

1. **SSL Certificate**: Add Let's Encrypt for HTTPS
2. **Domain Name**: Configure custom domain
3. **CDN**: Add CloudFlare for global performance
4. **Monitoring**: Add application monitoring
5. **Backup**: Automated backup strategy

---

## 📞 Support

For deployment issues or questions:
1. Check the troubleshooting section above
2. Review application logs
3. Test individual components
4. Verify network connectivity

**Happy deploying! 🚀**

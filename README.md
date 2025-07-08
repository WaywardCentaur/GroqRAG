# AI-Powered SaaS Demo - Real-Time Audio RAG Agent with React Frontend

This project implements a complete AI-powered SaaS demonstration with a React frontend and a Python backend featuring real-time audio transcription, document processing, and a RAG (Retrieval Augmented Generation) pipeline powered by Groq.

## 🚀 **Project Overview**

### **Frontend (React App)**
- **Modern React Interface**: Clean, responsive UI built with styled-components
- **YouTube Video Integration**: Embedded webinar playback with dual-tab support
- **Real-time Chat**: AI-powered chat interface for user interaction
- **Audio Capture**: Captures and transcribes audio from YouTube videos
- **Live Transcriptions**: Displays real-time transcriptions with video overlay

### **Backend (Python API)**
- **Real-time Audio Transcription**: Processes audio streams and converts to text
- **Document Processing**: Handles PDF, DOCX, TXT files for RAG pipeline
- **RAG Pipeline**: Uses Groq LLM for intelligent question answering
- **FastAPI REST API**: High-performance API with WebSocket support
- **Vector Storage**: ChromaDB for efficient document retrieval

## 🏗 **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  Python Backend │    │  External APIs  │
│                 │    │                 │    │                 │
│ • Video Player  │◄──►│ • FastAPI       │◄──►│ • Groq LLM      │
│ • Chat Interface│    │ • Audio Stream  │    │ • ChromaDB      │
│ • Transcriptions│    │ • RAG Pipeline  │    │ • YouTube API   │
│ • Dual Tabs     │    │ • WebSocket     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 **Prerequisites**

- **Node.js** (v14 or higher)
- **Python** (3.8 or higher)
- **Groq API Key**
- **Modern web browser** (for audio capture)

## 🛠 **Installation & Setup**

### **1. Clone the Repository**
```bash
git clone <repository-url>
cd GroqRAG
```

### **2. Backend Setup**

#### Install Python Dependencies
```bash
pip install -r requirements.txt
```

#### Environment Configuration
```bash
cp .env.example .env
# Edit .env with your configurations:
# GROQ_API_KEY=your_groq_api_key_here
# REACT_APP_API_URL=http://localhost:8001
```

#### Start the Backend Server
```bash
python src/main.py
```
*Backend will run on: http://localhost:8001*

### **3. Frontend Setup**

#### Navigate to React App
```bash
cd anna-webinar-demo
```

#### Install Node Dependencies
```bash
npm install
```

#### Environment Configuration
```bash
# Create .env.local file
echo "REACT_APP_API_URL=http://localhost:8001" > .env.local
```

#### Start the React App
```bash
npm start
```
*Frontend will run on: http://localhost:3000*

## 🎯 **Usage**

### **Starting the Demo**

1. **Open the React App**: Navigate to http://localhost:3000
2. **Click the Robot Button**: Press "Start AI Demo" to begin
3. **Video Playback**: YouTube video starts automatically
4. **Player Tab Opens**: Secondary tab opens for audio capture
5. **Start Recording**: Use controls in the player tab to capture audio
6. **Live Transcriptions**: See real-time transcriptions on the main video
7. **Ask Questions**: Use the chat interface to ask questions about the content

### **Key Features**

#### **Video Experience**
- **Clean Interface**: Robot start button with modern styling
- **YouTube Integration**: Embedded webinar video playback
- **Dual-Tab Mode**: Synchronized video playback across tabs
- **Live Indicators**: Real-time status and connection indicators

#### **Audio Processing**
- **Real-time Capture**: Captures audio directly from YouTube video
- **Live Transcription**: Displays transcriptions with video overlay
- **Smart Processing**: Processes audio through Groq's speech-to-text
- **Background Sync**: Audio processing happens in player tab

#### **AI Chat Interface**
- **Context-Aware**: AI understands video content and documents
- **Real-time Responses**: Powered by Groq's fast LLM inference
- **Document RAG**: Answers based on processed documents
- **Connection Status**: Shows backend connectivity status

## 📁 **Project Structure**

```
GroqRAG/
├── README.md                     # This file
├── requirements.txt              # Python dependencies
├── .env.example                  # Environment template
├── src/                          # Backend source code
│   ├── main.py                   # FastAPI application entry
│   ├── api/                      # API routes and handlers
│   │   ├── __init__.py
│   │   └── routes.py
│   └── core/                     # Core functionality
│       ├── __init__.py
│       ├── audio_processor.py    # Audio processing
│       ├── config.py             # Configuration
│       └── rag_pipeline.py       # RAG implementation
├── data/                         # Data storage
│   └── chromadb/                 # Vector database
├── tests/                        # Backend tests
├── anna-webinar-demo/            # React frontend
│   ├── README.md                 # React-specific README
│   ├── package.json              # Node dependencies
│   ├── src/                      # React source code
│   │   ├── App.js                # Main App component
│   │   ├── AnnaWebinarFixed.js   # Main demo component
│   │   ├── apiService.js         # API communication
│   │   ├── audioStreamService.js # Audio streaming
│   │   └── youtubeSyncService.js # YouTube synchronization
│   └── public/                   # Static files
│       ├── index.html
│       ├── youtube-player-clean.html
│       └── robot-svgrepo-com_copie_2.png
└── deployment/                   # Deployment configurations
```

## 🔧 **Available Scripts**

### **Backend Scripts**
```bash
# Start the server
python src/main.py

# Run tests
pytest tests/

# Check code quality
flake8 src/
```

### **Frontend Scripts**
```bash
# Development server
npm start

# Build for production
npm run build

# Run tests
npm test

# Lint code
npm run lint
```

## 🌐 **API Endpoints**

### **Health Check**
```
GET /health
Response: {"status": "healthy"}
```

### **Query AI**
```
POST /query
Body: {"text": "Your question here"}
Response: "AI response based on RAG pipeline"
```

### **Audio Stream**
```
WebSocket /ws/audio
- Accepts audio chunks
- Returns real-time transcriptions
```

## 🚀 **Deployment**

### **Development**
1. Start backend: `python src/main.py`
2. Start frontend: `npm start`
3. Open http://localhost:3000

### **Production**
1. Build React app: `npm run build`
2. Serve static files with backend
3. Configure environment variables
4. Use process manager (PM2, systemd)

## 🔑 **Environment Variables**

### **Backend (.env)**
```bash
GROQ_API_KEY=your_groq_api_key
CHROMA_DB_PATH=./data/chromadb
LOG_LEVEL=INFO
CORS_ORIGINS=http://localhost:3000
```

### **Frontend (.env.local)**
```bash
REACT_APP_API_URL=http://localhost:8001
```

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 **License**

MIT License - see LICENSE file for details

## 🆘 **Troubleshooting**

### **Common Issues**

#### **Backend Won't Start**
- Check Python version (3.8+)
- Verify all dependencies installed
- Check Groq API key configuration

#### **Frontend Connection Issues**
- Verify backend is running on port 8001
- Check CORS configuration
- Confirm API URL in .env.local

#### **Audio Capture Not Working**
- Allow microphone permissions in browser
- Check if player tab opened successfully
- Verify YouTube video is playing

#### **Transcriptions Not Appearing**
- Check browser console for errors
- Verify WebSocket connection
- Check Groq API key and quota

### **Support**

For issues and questions:
1. Check the troubleshooting section
2. Review browser console logs
3. Check backend logs
4. Create an issue with detailed information

---

**Built with ❤️ using React, FastAPI, and Groq**

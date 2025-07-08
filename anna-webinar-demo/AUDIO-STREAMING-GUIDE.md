# Audio Streaming Integration - Anna Webinar Demo

## 🎵 New Audio Streaming Features Added

Your Anna Webinar Demo now includes real-time audio streaming integration with your Groq RAG backend!

### ✅ Features Added

1. **Live Audio Streaming**: Streams audio from webinar to your RAG backend
2. **Real-time Transcription**: Shows live transcriptions from the audio
3. **Audio Controls**: Start/stop audio streaming with visual controls
4. **Microphone Support**: Can also stream from user's microphone
5. **Live Transcription Display**: Overlay showing recent transcriptions
6. **Chat Integration**: Transcriptions appear in the chat interface

### 🎛️ Audio Controls

- **🎤 Button**: Start/stop audio streaming
- **📝 Button**: Toggle live transcription display
- **LIVE indicator**: Shows when audio stream is connected

### 🔧 How It Works

1. **Video Audio Streaming**: When video plays, audio can be streamed to backend
2. **WebSocket Connection**: Uses `/audio` endpoint for real-time processing
3. **Live Transcriptions**: Backend transcribes audio and sends back text
4. **RAG Integration**: Transcriptions are added to RAG knowledge base
5. **Chat Context**: Transcriptions provide context for user questions

### 🚀 Updated Components

#### New Files:
- `src/audioStreamService.js` - WebSocket audio streaming service

#### Updated Files:
- `src/AnnaWebinar.js` - Added audio streaming controls and UI
- Audio streaming state management
- Live transcription display
- Enhanced chat interface

### 🎯 Usage Flow

1. **Start Webinar**: Click play button to start video
2. **Enable Audio Streaming**: Click 🎤 button to start streaming audio
3. **View Live Transcriptions**: Click 📝 to show/hide live transcriptions
4. **Ask Questions**: Chat with AI using context from audio transcriptions
5. **Real-time Updates**: See transcriptions in chat and overlay

### 🔗 Backend Integration

The frontend connects to your existing WebSocket endpoint:
- **Endpoint**: `ws://45.32.212.233:8000/audio`
- **Audio Format**: PCM 16-bit, 16kHz, mono
- **Protocol**: JSON messages with base64 audio data

### 🎪 Demo Features

#### Visual Indicators:
- **Connection Status**: Shows if audio stream is connected
- **Streaming Status**: Visual feedback when streaming is active
- **Live Badge**: Indicates real-time processing
- **Transcription Overlay**: Shows recent transcriptions

#### Audio Processing:
- **Video Audio**: Captures audio from video element
- **Microphone**: Alternative input for user questions
- **Real-time Processing**: Continuous audio streaming
- **Automatic Transcription**: Backend processes and returns text

### 🛠️ Technical Details

#### Audio Processing:
```javascript
// Audio context setup for video streaming
const audioContext = new AudioContext({ sampleRate: 16000 });
const source = audioContext.createMediaElementSource(videoElement);
const processor = audioContext.createScriptProcessor(4096, 1, 1);
```

#### WebSocket Protocol:
```javascript
// Sending audio data
{
  type: 'audio_data',
  data: 'base64-encoded-audio',
  format: 'pcm_s16le',
  channels: 1,
  sample_rate: 16000
}

// Receiving transcriptions
{
  type: 'transcription',
  text: 'transcribed text',
  timestamp: '2025-01-08T...'
}
```

### 🎮 User Experience

1. **Seamless Integration**: Audio streaming works alongside existing chat
2. **Visual Feedback**: Clear indicators for all streaming states
3. **Non-intrusive**: Transcriptions can be hidden/shown as needed
4. **Context-aware**: AI responses benefit from audio context
5. **Real-time**: Low latency audio processing and transcription

### 🚀 Deployment

The audio streaming features are included in your deployment:
- Works with existing deployment scripts
- No additional backend changes needed
- Uses your existing `/audio` WebSocket endpoint
- Compatible with all browsers supporting Web Audio API

### 🧪 Testing Audio Streaming

1. Deploy the updated app: `./deploy-simple.sh`
2. Access: http://45.32.212.233:3000
3. Click play to start webinar
4. Click 🎤 to start audio streaming
5. Watch for live transcriptions
6. Ask questions about the audio content

The AI will now have context from both the streamed audio transcriptions and any documents you've uploaded to your RAG system! 🎉

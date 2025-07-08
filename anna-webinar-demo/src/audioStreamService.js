// WebSocket Audio Service for streaming audio to the RAG backend
import config from './config';

class AudioStreamService {
  constructor() {
    this.socket = null;
    this.mediaRecorder = null;
    this.audioContext = null;
    this.isConnected = false;
    this.isRecording = false;
    this.onTranscription = null;
    this.onError = null;
    this.onConnectionChange = null;
    this.audioChunks = [];
  }

  // Connect to WebSocket
  async connect() {
    try {
      const wsUrl = `${config.WS_BASE_URL}${config.endpoints.audio}`;
      this.socket = new WebSocket(wsUrl);

      this.socket.onopen = () => {
        console.log('🔌 Audio WebSocket connected');
        this.isConnected = true;
        this.onConnectionChange?.(true);
        
        // Send ping to keep connection alive
        this.sendPing();
        this.pingInterval = setInterval(() => this.sendPing(), 30000);
      };    this.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        console.log('📩 Message received from backend:', data);
        this.handleMessage(data);
      } catch (error) {
        console.error('❌ Error parsing WebSocket message:', error);
      }
    };

      this.socket.onclose = () => {
        console.log('🔌 Audio WebSocket disconnected');
        this.isConnected = false;
        this.onConnectionChange?.(false);
        this.cleanup();
      };

      this.socket.onerror = (error) => {
        console.error('🔌 Audio WebSocket error:', error);
        this.onError?.(error);
      };

    } catch (error) {
      console.error('Failed to connect to audio WebSocket:', error);
      this.onError?.(error);
    }
  }

  // Handle incoming messages
  handleMessage(data) {
    switch (data.type) {
      case 'transcription':
        console.log('✅ Backend transcription result:', {
          text: data.text,
          confidence: data.confidence || 'N/A',
          timestamp: data.timestamp || new Date().toISOString(),
          processing_time: data.processing_time || 'N/A'
        });
        this.onTranscription?.(data);
        break;
      case 'error':
        console.error('❌ Backend transcription error:', data.message);
        this.onError?.(new Error(data.message));
        break;
      case 'pong':
        console.log('🏓 Backend keepalive received');
        break;
      case 'status':
        console.log('📊 Backend status:', data.message);
        break;
      default:
        console.log('❓ Unknown message from backend:', data);
    }
  }

  // Send ping to keep connection alive
  sendPing() {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({ type: 'ping' }));
    }
  }

  // Start recording from microphone (for user questions)
  async startMicrophoneRecording() {
    try {
      if (!this.isConnected) {
        await this.connect();
      }

      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          channelCount: 1,
          sampleRate: 16000,
          echoCancellation: true,
          noiseSuppression: true
        } 
      });

      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: 16000
      });

      const source = this.audioContext.createMediaStreamSource(stream);
      const processor = this.audioContext.createScriptProcessor(4096, 1, 1);

      processor.onaudioprocess = (event) => {
        if (this.isRecording) {
          const audioData = event.inputBuffer.getChannelData(0);
          this.sendAudioChunk(audioData);
        }
      };

      source.connect(processor);
      processor.connect(this.audioContext.destination);

      this.isRecording = true;
      this.stream = stream;
      this.processor = processor;

      console.log('🎤 Microphone recording started');
      return true;

    } catch (error) {
      console.error('Failed to start microphone recording:', error);
      this.onError?.(error);
      return false;
    }
  }

  // Start streaming from video/audio element
  async startVideoAudioStreaming(videoElement) {
    try {
      if (!this.isConnected) {
        await this.connect();
      }

      // Create audio context if not exists
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
          sampleRate: 16000
        });
      }

      // Create media element source
      const source = this.audioContext.createMediaElementSource(videoElement);
      const processor = this.audioContext.createScriptProcessor(4096, 1, 1);

      // Process audio chunks
      processor.onaudioprocess = (event) => {
        if (this.isRecording) {
          const audioData = event.inputBuffer.getChannelData(0);
          this.sendAudioChunk(audioData);
        }
      };

      // Connect audio nodes
      source.connect(processor);
      processor.connect(this.audioContext.destination);

      this.isRecording = true;
      this.processor = processor;
      this.audioSource = source;

      console.log('🎵 Video audio streaming started');
      return true;

    } catch (error) {
      console.error('Failed to start video audio streaming:', error);
      this.onError?.(error);
      return false;
    }
  }

  // Start recording from tab audio using Screen Capture API
  async startTabAudioRecording() {
    try {
      if (!this.isConnected) {
        await this.connect();
      }

      console.log('📣 Requesting display media with audio capture...');
      
      // Request screen/tab capture with audio (video required for compatibility)
      // Using less restrictive constraints to improve compatibility
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: true
      });

      // Check if audio track is available
      const audioTracks = stream.getAudioTracks();
      if (audioTracks.length === 0) {
        throw new Error('No audio track available in the captured stream. Did you check "Share tab audio" in the dialog?');
      }

      console.log('🔊 Tab audio capture started:', {
        tracks: audioTracks.length,
        label: audioTracks[0].label,
        settings: audioTracks[0].getSettings(),
        constraints: audioTracks[0].getConstraints()
      });

      // Create audio context for processing
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: 16000
      });

      const source = this.audioContext.createMediaStreamSource(stream);
      const processor = this.audioContext.createScriptProcessor(4096, 1, 1);

      processor.onaudioprocess = (event) => {
        if (this.isRecording) {
          const audioData = event.inputBuffer.getChannelData(0);
          this.sendAudioChunk(audioData);
        }
      };

      source.connect(processor);
      processor.connect(this.audioContext.destination);

      this.isRecording = true;
      this.stream = stream;
      this.processor = processor;
      this.audioSource = source;

      // Handle stream end (user stops sharing)
      stream.getAudioTracks()[0].onended = () => {
        console.log('🔊 Tab audio capture ended by user');
        this.stopTabAudioRecording();
      };

      console.log('🔊 Tab audio recording started successfully');
      return true;

    } catch (error) {
      console.error('Failed to start tab audio recording:', error);
      this.onError?.(error);
      return false;
    }
  }

  // Send audio chunk to server
  sendAudioChunk(audioData) {
    if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
      console.warn('🔌 WebSocket not connected, skipping audio chunk');
      return;
    }

    // Check if audioData contains actual audio signal
    const hasAudioSignal = this.detectAudioSignal(audioData);
    if (!hasAudioSignal && (this.noSignalCount || 0) % 30 === 0) {
      console.warn('⚠️ No audio signal detected in chunk');
      this.noSignalCount = (this.noSignalCount || 0) + 1;
    }

    try {
      // Convert Float32Array to Int16Array
      const int16Array = new Int16Array(audioData.length);
      for (let i = 0; i < audioData.length; i++) {
        int16Array[i] = Math.max(-32768, Math.min(32767, audioData[i] * 32768));
      }

      // Convert to base64
      const audioBase64 = btoa(String.fromCharCode.apply(null, new Uint8Array(int16Array.buffer)));

      const message = {
        type: 'audio_data',
        data: audioBase64,
        format: 'pcm_s16le',
        channels: 1,
        sample_rate: 16000,
        samples: int16Array.length
      };

      this.socket.send(JSON.stringify(message));
      
      // Log audio data being sent (every 10th chunk to avoid spam)
      if (this.chunkCount % 10 === 0) {
        console.log('🔊 Audio chunk sent to backend:', {
          samples: int16Array.length,
          format: message.format,
          sampleRate: message.sample_rate,
          dataSize: audioBase64.length + ' bytes'
        });
      }
      this.chunkCount = (this.chunkCount || 0) + 1;
      
    } catch (error) {
      console.error('❌ Failed to send audio chunk:', error);
    }
  }

  // Stop recording
  stopRecording() {
    this.isRecording = false;

    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }

    if (this.processor) {
      this.processor.disconnect();
      this.processor = null;
    }

    if (this.audioSource) {
      this.audioSource.disconnect();
      this.audioSource = null;
    }

    console.log('🛑 Audio recording stopped');
  }

  // Stop tab audio recording
  async stopTabAudioRecording() {
    try {
      this.isRecording = false;

      if (this.processor) {
        this.processor.disconnect();
        this.processor = null;
      }

      if (this.audioSource) {
        this.audioSource.disconnect();
        this.audioSource = null;
      }

      if (this.stream) {
        this.stream.getTracks().forEach(track => track.stop());
        this.stream = null;
      }

      if (this.audioContext && this.audioContext.state !== 'closed') {
        await this.audioContext.close();
        this.audioContext = null;
      }

      console.log('🔊 Tab audio recording stopped');
      return true;

    } catch (error) {
      console.error('Failed to stop tab audio recording:', error);
      return false;
    }
  }

  // Disconnect and cleanup
  disconnect() {
    this.stopRecording();
    
    if (this.socket) {
      this.socket.send(JSON.stringify({ type: 'stop' }));
      this.socket.close();
    }

    this.cleanup();
  }

  // Cleanup resources
  cleanup() {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
    }

    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close();
      this.audioContext = null;
    }

    this.socket = null;
    this.isConnected = false;
    this.isRecording = false;
  }

  // Event handlers
  onTranscriptionReceived(callback) {
    this.onTranscription = callback;
  }

  onErrorOccurred(callback) {
    this.onError = callback;
  }

  onConnectionChanged(callback) {
    this.onConnectionChange = callback;
  }
}

export default new AudioStreamService();

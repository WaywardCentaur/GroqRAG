// YouTube Video Sync Service for cross-tab communication
class YouTubeSyncService {
  constructor() {
    this.isController = false;
    this.isPlayer = false;
    this.syncChannel = null;
    this.playerWindow = null;
    this.onSyncMessage = null;
    this.videoId = null;
    this.currentTime = 0;
    this.isPlaying = false;
  }

  // Initialize as controller (main tab)
  initController(videoId) {
    this.isController = true;
    this.videoId = videoId;
    
    // Create broadcast channel for communication
    this.syncChannel = new BroadcastChannel('youtube-sync');
    
    this.syncChannel.onmessage = (event) => {
      console.log('🎬 Sync message received:', event.data);
      this.handleSyncMessage(event.data);
    };

    console.log('🎬 YouTube sync controller initialized');
  }

  // Initialize as player (video tab)
  initPlayer() {
    this.isPlayer = true;
    
    // Create broadcast channel for communication
    this.syncChannel = new BroadcastChannel('youtube-sync');
    
    this.syncChannel.onmessage = (event) => {
      console.log('🎬 Player received command:', event.data);
      this.handlePlayerCommand(event.data);
    };

    // Notify controller that player is ready
    this.sendToController({
      type: 'player_ready',
      timestamp: Date.now()
    });

    console.log('🎬 YouTube sync player initialized');
  }

  // Open video player in new tab
  openPlayerTab(videoId) {
    const playerUrl = `${window.location.origin}/youtube-player-clean.html?videoId=${videoId}`;
    
    this.playerWindow = window.open(
      playerUrl,
      'youtube-player',
      'width=900,height=700,menubar=no,toolbar=no,location=no,status=no'
    );

    if (this.playerWindow) {
      console.log('🎬 Player tab opened:', playerUrl);
      return true;
    } else {
      console.error('❌ Failed to open player tab - popup blocked?');
      return false;
    }
  }

  // Send command to player tab
  sendToPlayer(command) {
    if (this.syncChannel) {
      this.syncChannel.postMessage({
        target: 'player',
        ...command
      });
      console.log('🎬 Command sent to player:', command);
    }
  }

  // Send video sync commands
  syncPlayState(isPlaying, currentTime = null) {
    this.sendToPlayer({
      type: 'sync_play_state',
      isPlaying: isPlaying,
      currentTime: currentTime,
      timestamp: Date.now()
    });
  }

  syncVideoTime(currentTime) {
    this.sendToPlayer({
      type: 'sync_time',
      currentTime: currentTime,
      timestamp: Date.now()
    });
  }

  // Send message to controller tab
  sendToController(message) {
    if (this.syncChannel) {
      this.syncChannel.postMessage({
        target: 'controller',
        ...message
      });
      console.log('🎬 Message sent to controller:', message);
    }
  }

  // Handle sync messages from player
  handleSyncMessage(data) {
    if (data.target !== 'controller') return;

    switch (data.type) {
      case 'player_ready':
        console.log('✅ Player tab is ready');
        this.onSyncMessage?.({ type: 'player_ready' });
        break;
      case 'time_update':
        this.currentTime = data.currentTime;
        this.onSyncMessage?.({ type: 'time_update', currentTime: data.currentTime });
        break;
      case 'play_state_change':
        this.isPlaying = data.isPlaying;
        this.onSyncMessage?.({ type: 'play_state_change', isPlaying: data.isPlaying });
        break;
      case 'audio_permission_granted':
        console.log('🔊 Audio permission granted in player tab');
        this.onSyncMessage?.({ type: 'audio_ready' });
        break;
      case 'audio_transcription':
        console.log('📝 Transcription from player tab:', data);
        
        // Ensure consistent data format for the main app
        const transcriptionData = {
          type: 'transcription',
          text: data.text || '',
          timestamp: data.timestamp || Date.now(),
          confidence: data.confidence,
          processing_time: data.processing_time
        };
        
        console.log('📤 Forwarding transcription to main app:', transcriptionData);
        this.onSyncMessage?.(transcriptionData);
        break;
    }
  }

  // Handle commands from controller (when this is player tab)
  handlePlayerCommand(data) {
    if (data.target !== 'player') return;

    switch (data.type) {
      case 'play':
        this.playVideo();
        break;
      case 'pause':
        this.pauseVideo();
        break;
      case 'seek':
        this.seekTo(data.time);
        break;
      case 'start_audio_capture':
        this.startAudioCapture();
        break;
      case 'stop_audio_capture':
        this.stopAudioCapture();
        break;
    }
  }

  // Player tab methods
  playVideo() {
    const iframe = document.querySelector('iframe');
    if (iframe) {
      iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
    }
  }

  pauseVideo() {
    const iframe = document.querySelector('iframe');
    if (iframe) {
      iframe.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
    }
  }

  seekTo(time) {
    const iframe = document.querySelector('iframe');
    if (iframe) {
      iframe.contentWindow.postMessage(`{"event":"command","func":"seekTo","args":[${time}, true]}`, '*');
    }
  }

  // Start audio capture in player tab
  async startAudioCapture() {
    try {
      // Import audio service dynamically
      const { default: audioStreamService } = await import('./audioStreamService');
      
      // Connect to backend
      await audioStreamService.connect();
      
      // Start tab audio recording
      const success = await audioStreamService.startTabAudioRecording();
      
      if (success) {
        // Set up transcription handler
        audioStreamService.onTranscriptionReceived((data) => {
          this.sendToController({
            type: 'audio_transcription',
            text: data.text,
            timestamp: data.timestamp
          });
        });

        this.sendToController({
          type: 'audio_permission_granted'
        });
      }
    } catch (error) {
      console.error('❌ Failed to start audio capture in player tab:', error);
    }
  }

  // Controller tab methods
  play() {
    this.sendToPlayer({ type: 'play' });
    this.isPlaying = true;
  }

  pause() {
    this.sendToPlayer({ type: 'pause' });
    this.isPlaying = false;
  }

  seek(time) {
    this.sendToPlayer({ type: 'seek', time });
  }

  startAudioCapture() {
    this.sendToPlayer({ type: 'start_audio_capture' });
  }

  stopAudioCapture() {
    this.sendToPlayer({ type: 'stop_audio_capture' });
  }

  // Event handler
  onSyncMessageReceived(callback) {
    this.onSyncMessage = callback;
  }

  // Cleanup
  disconnect() {
    if (this.syncChannel) {
      this.syncChannel.close();
    }
    if (this.playerWindow && !this.playerWindow.closed) {
      this.playerWindow.close();
    }
  }
}

export default new YouTubeSyncService();

import React, { useState, useRef, useEffect, useCallback } from "react";
import styled from "styled-components";
import apiService from './apiService';
import audioStreamService from './audioStreamService';
import youtubeSyncService from './youtubeSyncService';

// --- Styled Components ---
const Page = styled.div`
  min-height: 100vh;
  background: #343946;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 32px 0;
`;

const WebinarWrapper = styled.div`
  background: linear-gradient(135deg, #f5f7fa 40%, #e4e7fb 100%);
  border-radius: 24px;
  box-shadow: 0 8px 32px rgba(44, 48, 62, 0.08);
  padding: 32px;
  display: flex;
  flex-direction: row;
  gap: 32px;
  max-width: 1400px;
  width: 100%;
  height: 800px;
`;

const VideoSection = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
`;

const ChatSection = styled.div`
  flex: 1;
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  overflow: hidden;
`;

const VideoPlayer = styled.div`
  width: 100%;
  height: 100%;
  background: #000;
  border-radius: 16px;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
`;

const PlayButton = styled.button`
  width: 80px;
  height: 80px;
  border-radius: 50%;
  border: none;
  background: rgba(106, 92, 255, 0.9);
  color: white;
  font-size: 32px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(10px);
  z-index: 10;

  &:hover {
    background: rgba(106, 92, 255, 1);
    transform: scale(1.1);
  }
`;

const PlayIcon = styled.div`
  width: 0;
  height: 0;
  border-left: 20px solid white;
  border-top: 12px solid transparent;
  border-bottom: 12px solid transparent;
  margin-left: 4px;
`;

const VideoLabel = styled.div`
  position: absolute;
  bottom: 20px;
  left: 20px;
  color: white;
  font-size: 18px;
  font-weight: 600;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(10px);
  background: rgba(0, 0, 0, 0.3);
  padding: 12px 16px;
  border-radius: 8px;
`;

const VideoControls = styled.div`
  position: absolute;
  top: 20px;
  left: 20px;
  display: flex;
  gap: 8px;
  color: white;
  font-size: 14px;
  font-weight: 600;
  backdrop-filter: blur(10px);
  background: rgba(0, 0, 0, 0.3);
  padding: 8px 12px;
  border-radius: 6px;
`;

const TranscriptionOverlay = styled.div`
  position: absolute;
  bottom: 16px;
  left: 16px;
  right: 16px;
  background: rgba(0, 0, 0, 0.9);
  color: white;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 0.9rem;
  max-height: 120px;
  overflow-y: auto;
  backdrop-filter: blur(10px);
  display: ${({ show }) => show ? 'block' : 'none'};
  z-index: 15;
`;

const TranscriptionText = styled.div`
  line-height: 1.4;
  margin-bottom: 8px;
  
  &:last-child {
    margin-bottom: 0;
  }
`;

const ChatHeader = styled.div`
  background: #6a5cff;
  color: white;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
`;

const AssistantName = styled.h3`
  margin: 0;
  font-size: 18px;
  font-weight: 600;
`;

const AssistantDesc = styled.p`
  margin: 0;
  font-size: 14px;
  opacity: 0.9;
  display: flex;
  align-items: center;
  gap: 8px;
`;

const StatusIndicator = styled.div`
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  opacity: 0.8;
`;

const StatusDot = styled.div`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: ${({ status }) => 
    status === 'connected' ? '#22c55e' : 
    status === 'disconnected' ? '#ef4444' : '#f59e0b'};
`;

const ChatBody = styled.div`
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
`;

const MessageBubble = styled.div`
  max-width: 80%;
  padding: 12px 16px;
  border-radius: 16px;
  font-size: 14px;
  line-height: 1.4;
  align-self: ${({ from }) => from === "user" ? "flex-end" : "flex-start"};
  background: ${({ from }) => 
    from === "user" ? "#6a5cff" : 
    from === "transcription" ? "#fff3cd" : "#f3f5fa"};
  color: ${({ from }) => 
    from === "user" ? "white" : 
    from === "transcription" ? "#856404" : "#2c3e50"};
  border: ${({ from }) => 
    from === "transcription" ? "3px solid #ffc107" : "none"};
  
  strong {
    display: block;
    margin-bottom: 4px;
    font-size: 12px;
    opacity: 0.8;
  }
`;

const ChatInputArea = styled.div`
  border-top: 1px solid #e5e7eb;
  padding: 20px;
`;

const ChatInput = styled.input`
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  
  &:focus {
    border-color: #6a5cff;
    box-shadow: 0 0 0 3px rgba(106, 92, 255, 0.1);
  }
`;

const ControlPanel = styled.div`
  background: rgba(0, 0, 0, 0.8);
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 16px;
  display: flex;
  gap: 12px;
  align-items: center;
  flex-wrap: wrap;
`;

const ControlButton = styled.button`
  background: ${({ variant }) => 
    variant === 'primary' ? '#6a5cff' : 
    variant === 'danger' ? '#ef4444' : 
    variant === 'success' ? '#22c55e' : '#6b7280'};
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
  
  &:hover {
    opacity: 0.9;
    transform: translateY(-1px);
  }
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
  }
`;

const StatusDisplay = styled.div`
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: white;
  background: rgba(255, 255, 255, 0.1);
  padding: 6px 12px;
  border-radius: 6px;
`;

// --- Constants ---
const WEBINAR_VIDEO_ID = "GeUXQ_L-35M";

// --- Main Component ---
const AnnaWebinarDualTab = () => {
  // --- State ---
  const [playing, setPlaying] = useState(false);
  const [chatOpen, setChatOpen] = useState(false);
  const [messages, setMessages] = useState([
    { 
      from: "assistant", 
      text: "Hi! I'm Anna, your AI assistant. I'm here to help you understand this webinar about AI-powered SaaS solutions. Start the video and I'll provide insights based on what's being discussed!" 
    }
  ]);
  const [inputValue, setInputValue] = useState("");
  const [loading, setLoading] = useState(false);
  const [showTranscriptions, setShowTranscriptions] = useState(false);
  const [liveTranscriptions, setLiveTranscriptions] = useState([]);
  
  // Connection states
  const [backendConnected, setBackendConnected] = useState(false);
  const [playerTabReady, setPlayerTabReady] = useState(false);
  const [audioStreamConnected, setAudioStreamConnected] = useState(false);
  
  // Refs
  const chatBodyRef = useRef(null);

  // --- Player Tab Management ---
  const openPlayerTab = useCallback(() => {
    const playerUrl = `${window.location.origin}/youtube-player-clean.html?videoId=${WEBINAR_VIDEO_ID}`;
    
    const playerWindow = window.open(
      playerUrl,
      'youtube-player',
      'width=900,height=700,menubar=no,toolbar=no,location=no,status=no'
    );

    if (playerWindow) {
      console.log('🎬 Player tab opened:', playerUrl);
      return true;
    } else {
      console.error('❌ Failed to open player tab - popup blocked?');
      alert('Unable to open player tab. Please allow popups for this site.');
      return false;
    }
  }, []);

  const openDebugPlayerTab = useCallback(() => {
    const playerUrl = `${window.location.origin}/debug-player.html?videoId=${WEBINAR_VIDEO_ID}`;
    
    const debugWindow = window.open(
      playerUrl,
      'youtube-debug-player',
      'width=900,height=800,menubar=no,toolbar=no,location=no,status=no'
    );

    if (debugWindow) {
      console.log('🐞 Debug player tab opened:', playerUrl);
      return true;
    } else {
      console.error('❌ Failed to open debug player tab - popup blocked?');
      alert('Unable to open debug player tab. Please allow popups for this site.');
      return false;
    }
  }, []);

  // --- Video Control ---
  const startVideo = useCallback(() => {
    setPlaying(true);
    setChatOpen(true);
    
    // Automatically open player tab when video starts
    setTimeout(() => {
      const success = openPlayerTab();
      if (!success) {
        console.warn('Failed to open player tab - user will need to manually open it');
      }
    }, 500);
  }, [openPlayerTab]);

  const stopVideo = useCallback(() => {
    setPlaying(false);
    setChatOpen(false);
    setLiveTranscriptions([]);
    setShowTranscriptions(false);
  }, []);

  // --- Backend Communication ---
  const sendMessage = async () => {
    if (!inputValue.trim() || loading || !backendConnected) return;
    
    const userMessage = inputValue.trim();
    setInputValue("");
    setLoading(true);
    
    setMessages(prev => [...prev, { from: "user", text: userMessage }]);
    
    try {
      const response = await apiService.sendMessage(userMessage);
      setMessages(prev => [...prev, { from: "assistant", text: response }]);
    } catch (error) {
      console.error('Error sending message:', error);
      setMessages(prev => [...prev, { 
        from: "assistant", 
        text: "Sorry, I'm having trouble connecting to the backend. Please try again." 
      }]);
    } finally {
      setLoading(false);
    }
  };

  // --- Effects ---
  useEffect(() => {
    // Test backend connection
    const testConnection = async () => {
      try {
        const response = await fetch(`${process.env.REACT_APP_API_URL}/health`);
        setBackendConnected(response.ok);
      } catch (error) {
        console.error('Backend connection failed:', error);
        setBackendConnected(false);
      }
    };

    testConnection();
    const interval = setInterval(testConnection, 30000); // Check every 30 seconds
    
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    // Initialize YouTube sync service
    youtubeSyncService.initController(WEBINAR_VIDEO_ID);
    
    // Set up sync message handler
    youtubeSyncService.onSyncMessageReceived((message) => {
      console.log('📨 Sync message received:', message);
      
      switch (message.type) {
        case 'player_ready':
          setPlayerTabReady(true);
          console.log('✅ Player tab is ready for audio capture');
          break;
          
        case 'audio_ready':
          setAudioStreamConnected(true);
          console.log('🔊 Audio capture ready in player tab');
          break;
          
        case 'transcription':
          console.log('📝 Transcription received:', {
            text: message.text,
            timestamp: message.timestamp
          });
          
          // Add to live transcriptions with unique ID
          setLiveTranscriptions(prev => {
            const newTranscriptions = [...prev, {
              id: `transcription-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
              text: message.text,
              timestamp: message.timestamp || Date.now()
            }];
            // Keep only the last 3 transcriptions
            return newTranscriptions.slice(-3);
          });
          
          // Auto-show transcriptions when they start coming in
          if (!showTranscriptions) {
            setShowTranscriptions(true);
          }
          
          break;
      }
    });

    return () => {
      youtubeSyncService.disconnect();
    };
  }, [showTranscriptions]);

  useEffect(() => {
    // Auto-scroll chat to bottom
    if (chatBodyRef.current) {
      chatBodyRef.current.scrollTop = chatBodyRef.current.scrollHeight;
    }
  }, [messages]);

  // --- Render ---
  return (
    <Page>
      <WebinarWrapper>
        {/* Video Section */}
        <VideoSection>
          <VideoPlayer>
            {!playing && (
              <>
                <PlayButton onClick={startVideo}>
                  <PlayIcon />
                </PlayButton>
                <VideoLabel>
                  AI-Powered SaaS Demo<br/>
                  Click to play webinar
                </VideoLabel>
              </>
            )}
            
            {playing && (
              <>
                {/* Video Playing Indicator */}
                <div style={{
                  position: 'absolute',
                  top: '50%',
                  left: '50%',
                  transform: 'translate(-50%, -50%)',
                  textAlign: 'center',
                  color: 'white',
                  zIndex: 5
                }}>
                  <div style={{ fontSize: '48px', marginBottom: '16px' }}>🎬</div>
                  <div style={{ fontSize: '24px', fontWeight: '600', marginBottom: '8px' }}>
                    Video Playing in Separate Tab
                  </div>
                  <div style={{ fontSize: '16px', opacity: 0.8 }}>
                    Switch to the player tab to see the video
                  </div>
                  {!playerTabReady && (
                    <div style={{ 
                      fontSize: '14px', 
                      color: '#ffc107', 
                      marginTop: '12px',
                      background: 'rgba(255, 193, 7, 0.2)',
                      padding: '8px 12px',
                      borderRadius: '6px'
                    }}>
                      ⚠️ Waiting for player tab to load...
                    </div>
                  )}
                </div>
                
                <VideoControls>
                  <span>🔴 LIVE</span>
                  <span>•</span>
                  <span>AI-Powered SaaS Demo</span>
                </VideoControls>
                
                {/* Transcription Overlay */}
                <TranscriptionOverlay show={showTranscriptions && liveTranscriptions.length > 0}>
                  {liveTranscriptions.map((transcription) => (
                    <TranscriptionText key={transcription.id}>
                      {transcription.text}
                    </TranscriptionText>
                  ))}
                </TranscriptionOverlay>
              </>
            )}
          </VideoPlayer>
          
          {/* Control Panel */}
          <ControlPanel>
            <ControlButton 
              variant={playing ? 'danger' : 'primary'}
              onClick={playing ? stopVideo : startVideo}
              disabled={!backendConnected}
            >
              {playing ? '⏹️ Stop Video' : '▶️ Start Video'}
            </ControlButton>
            
            <ControlButton 
              variant={showTranscriptions ? 'success' : 'default'}
              onClick={() => setShowTranscriptions(!showTranscriptions)}
            >
              {showTranscriptions ? '👁️ Hide Transcriptions' : '👁️ Show Transcriptions'}
            </ControlButton>
            
            <ControlButton 
              variant="default"
              onClick={openPlayerTab}
              disabled={!playing}
            >
              🎬 Open Player Tab
            </ControlButton>
            
            <ControlButton 
              variant="default"
              onClick={openDebugPlayerTab}
            >
              🐞 Debug Player
            </ControlButton>
            
            <StatusDisplay>
              <StatusDot status={backendConnected ? 'connected' : 'disconnected'} />
              Backend: {backendConnected ? 'Connected' : 'Disconnected'}
            </StatusDisplay>
            
            {playerTabReady && (
              <StatusDisplay>
                <StatusDot status="connected" />
                Player Tab: Ready
              </StatusDisplay>
            )}
            
            {audioStreamConnected && (
              <StatusDisplay>
                <StatusDot status="connected" />
                Audio: Streaming
              </StatusDisplay>
            )}
          </ControlPanel>
        </VideoSection>

        {/* Chat Section - Only show when video is playing */}
        {(chatOpen || playing) && (
          <ChatSection>
            <ChatHeader>
              <AssistantName>Anna AI Assistant</AssistantName>
              <AssistantDesc>
                Powered by AI – based on video & product data
                {audioStreamConnected && (
                  <span style={{ color: '#22c55e' }}>
                    🔊 Audio streaming from player tab
                  </span>
                )}
              </AssistantDesc>
              <StatusIndicator>
                <StatusDot status={backendConnected ? 'connected' : 'disconnected'} />
                {backendConnected ? 'Connected' : 'Offline'}
              </StatusIndicator>
            </ChatHeader>
            
            <ChatBody ref={chatBodyRef}>
              {messages.map((msg, i) => (
                <MessageBubble key={i} from={msg.from}>
                  {msg.from === "assistant" && <strong>Anna AI</strong>}
                  {msg.from === "transcription" && <strong>Live Transcription</strong>}
                  {msg.text}
                </MessageBubble>
              ))}
              {loading && (
                <MessageBubble from="assistant">
                  <strong>Anna AI</strong>
                  Thinking...
                </MessageBubble>
              )}
            </ChatBody>
            
            <ChatInputArea>
              <ChatInput
                type="text"
                placeholder="Ask Anna about the webinar..."
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
                disabled={loading || !backendConnected}
              />
            </ChatInputArea>
          </ChatSection>
        )}
      </WebinarWrapper>
    </Page>
  );
};

export default AnnaWebinarDualTab;

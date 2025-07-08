import React, { useState, useRef, useEffect } from "react";
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
  width: 90vw;
  max-width: 1200px;
  min-height: 500px;

  @media (max-width: 900px) {
    flex-direction: column;
    align-items: stretch;
    padding: 16px;
    gap: 16px;
    max-width: 100vw;
  }
`;

const VideoSection = styled.div`
  flex: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 0;
`;

const VideoPlayer = styled.div`
  background: #232732;
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(44, 48, 62, 0.08);
  width: 100%;
  max-width: 560px;
  min-height: 320px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  margin-bottom: 24px;
  overflow: hidden;

  @media (max-width: 600px) {
    max-width: 100vw;
    min-height: 180px;
  }
`;

const VideoElement = styled.video`
  width: 100%;
  height: 100%;
  border-radius: 16px;
  object-fit: cover;
  display: ${({ show }) => show ? 'block' : 'none'};
`;

const YouTubeFrame = styled.iframe`
  width: 100%;
  height: 320px;
  border-radius: 16px;
  border: none;
  display: ${({ show }) => show ? 'block' : 'none'};
`;

// AudioControls and AudioButton removed - no longer needed

const LiveTranscription = styled.div`
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
  
  &:not(:last-child) {
    opacity: 0.7;
  }
`;

const VideoControls = styled.div`
  position: absolute;
  bottom: 16px;
  right: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(0, 0, 0, 0.7);
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  color: white;
  z-index: 10;
`;

const StartVideoButton = styled.button`
  border: none;
  background: #6a5cff;
  cursor: pointer;
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  padding: 20px;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  box-shadow: 0 8px 32px rgba(106, 92, 255, 0.3);
  transition: all 0.3s ease;

  &:hover {
    background: #5240ff;
    transform: translate(-50%, -50%) scale(1.05);
    box-shadow: 0 12px 48px rgba(106, 92, 255, 0.4);
  }

  &:active {
    transform: translate(-50%, -50%) scale(0.98);
  }
`;

const RobotImage = styled.img`
  width: 64px;
  height: 64px;
  filter: brightness(0) invert(1);
`;

const ButtonLabel = styled.div`
  color: white;
  font-size: 1.1rem;
  font-weight: 600;
  text-align: center;
  line-height: 1.3;
`;

const AudioModeSelector = styled.div`
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 16px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  font-size: 0.9rem;
`;

const ModeButton = styled.button`
  background: ${({ active }) => active ? '#6a5cff' : 'transparent'};
  color: ${({ active }) => active ? 'white' : '#ccc'};
  border: 1px solid ${({ active }) => active ? '#6a5cff' : '#666'};
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.2s;

  &:hover {
    background: ${({ active }) => active ? '#5240ff' : 'rgba(106, 92, 255, 0.2)'};
  }
`;

const NeedHelpBanner = styled.div`
  margin-top: 16px;
  padding: 18px 24px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(44, 48, 62, 0.06);
  display: flex;
  align-items: center;
  gap: 18px;
  justify-content: space-between;
`;

const HelpText = styled.div`
  color: #393e4c;
  font-weight: 500;
  font-size: 1.1rem;
`;

const StartButton = styled.button`
  background: #6a5cff;
  color: #fff;
  padding: 12px 24px;
  border-radius: 8px;
  border: none;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(44, 48, 62, 0.08);

  &:hover {
    background: #5240ff;
  }
`;

const ChatSection = styled.div`
  flex: 1.1;
  min-width: 320px;
  max-width: 420px;
  background: #fff;
  border-radius: 18px;
  box-shadow: 0 4px 32px rgba(44, 48, 62, 0.06);
  padding: 0 0 16px 0;
  display: flex;
  flex-direction: column;
  height: 100%;
`;

const ChatHeader = styled.div`
  padding: 18px 24px 8px 24px;
  border-radius: 18px 18px 0 0;
  background: #f7f8fa;
  border-bottom: 1px solid #edeef2;
  position: relative;
`;

const StatusIndicator = styled.div`
  position: absolute;
  top: 18px;
  right: 24px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.8rem;
  color: ${({ status }) => 
    status === 'connected' ? '#22c55e' : 
    status === 'disconnected' ? '#ef4444' : '#6b7280'};
`;

const StatusDot = styled.div`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: ${({ status }) => 
    status === 'connected' ? '#22c55e' : 
    status === 'disconnected' ? '#ef4444' : '#6b7280'};
`;

const AssistantName = styled.div`
  color: #6a5cff;
  font-weight: bold;
  font-size: 1rem;
`;

const AssistantDesc = styled.div`
  font-size: 0.88rem;
  color: #7b7f91;
  margin-top: 2px;
`;

const ChatBody = styled.div`
  flex: 1;
  overflow-y: auto;
  padding: 18px 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
`;

const MessageBubble = styled.div`
  background: ${({ from }) => 
    from === "user" ? "#e8e7fd" : 
    from === "transcription" ? "#fff3cd" : "#f3f5fa"};
  color: #393e4c;
  padding: 11px 16px;
  border-radius: 13px;
  max-width: 80%;
  align-self: ${({ from }) => (from === "user" ? "flex-end" : "flex-start")};
  font-size: 0.97rem;
  box-shadow: ${({ from }) =>
    from === "user"
      ? "0 2px 8px rgba(106,92,255,0.08)"
      : from === "transcription"
      ? "0 2px 8px rgba(255,193,7,0.15)"
      : "0 2px 8px rgba(44,48,62,0.04)"};
  border-left: ${({ from }) => 
    from === "transcription" ? "3px solid #ffc107" : "none"};
`;

const ChatFooter = styled.form`
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 18px;
  margin-top: 8px;
`;

const Input = styled.input`
  flex: 1;
  padding: 11px 16px;
  border-radius: 8px;
  border: 1px solid #dedff2;
  font-size: 1rem;
  background: #f7f8fa;
  outline: none;
`;

const SendBtn = styled.button`
  background: #6a5cff;
  color: #fff;
  border: none;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  opacity: ${({ disabled }) => disabled ? 0.5 : 1};
  cursor: ${({ disabled }) => disabled ? 'not-allowed' : 'pointer'};

  &:hover {
    background: ${({ disabled }) => disabled ? '#6a5cff' : '#5240ff'};
  }
`;

// Remove the old PlayIcon component - we're using the robot image instead

// --- Main Component ---
const AnnaWebinarFixed = () => {
  const [chatOpen, setChatOpen] = useState(false);
  const [playing, setPlaying] = useState(false);
  const [messages, setMessages] = useState([
    {
      from: "ai",
      text: "Hi! I'm your AI assistant. I can answer questions about the webinar content and our SaaS product. What would you like to know?",
    },
  ]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [serverStatus, setServerStatus] = useState('checking');
  
  // Audio streaming states
  const [isStreamingAudio, setIsStreamingAudio] = useState(false);
  const [audioStreamConnected, setAudioStreamConnected] = useState(false);
  const [showTranscriptions, setShowTranscriptions] = useState(false);
  const [liveTranscriptions, setLiveTranscriptions] = useState([]);
  const [playerTabReady, setPlayerTabReady] = useState(false);
  const syncMode = 'dual-tab'; // Always use dual-tab mode
  
  const inputRef = useRef(null);
  const videoRef = useRef(null);
  const chatBodyRef = useRef(null);

  // YouTube webinar video ID (Anna Livingston Marketing webinar)
  const WEBINAR_VIDEO_ID = "GeUXQ_L-35M"; // Marketing webinar

  // Auto-scroll chat to bottom
  useEffect(() => {
    if (chatBodyRef.current) {
      chatBodyRef.current.scrollTop = chatBodyRef.current.scrollHeight;
    }
  }, [messages, chatOpen]);

  // Check server health on component mount
  useEffect(() => {
    const checkServerHealth = async () => {
      try {
        const response = await fetch(`${process.env.REACT_APP_API_URL}/health`);
        setServerStatus(response.ok ? 'connected' : 'disconnected');
      } catch (error) {
        setServerStatus('disconnected');
      }
    };

    checkServerHealth();
    const interval = setInterval(checkServerHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  // Set up audio stream service and YouTube sync
  useEffect(() => {
    // Initialize YouTube sync service as controller
    youtubeSyncService.initController(WEBINAR_VIDEO_ID);
    
    // Set up YouTube sync message handler
    youtubeSyncService.onSyncMessageReceived((message) => {
      console.log('🎬 Sync message received:', message);
      
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
          // Log but ignore the incoming show parameter, we'll use our own state
          console.log('📝 Transcription received in main app:', {
            text: message.text,
            timestamp: message.timestamp,
            receivedShowValue: message.show,
            receivedShowType: typeof message.show,
            // Our own state controls visibility, not incoming messages
            currentShowState: showTranscriptions
          });
          
          // Add to live transcriptions with unique ID to prevent React key issues
          setLiveTranscriptions(prev => {
            const newTranscriptions = [...prev, {
              id: `transcription-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
              text: message.text,
              timestamp: message.timestamp || Date.now()
            }];
            // Keep only the last 3 transcriptions
            return newTranscriptions.slice(-3);
          });
          
          // IMPORTANT: We don't modify showTranscriptions here anymore
          // This prevents unwanted toggling of the transcription state
          // User controls this explicitly via the toggle button
          
          break;
      }
    });

    // Set up regular audio stream event handlers (for fallback mode)
    audioStreamService.onConnectionChanged((connected) => {
      if (syncMode === 'single') {
        setAudioStreamConnected(connected);
      }
    });

    audioStreamService.onTranscriptionReceived((data) => {
      if (syncMode === 'single') {
        console.log('� New transcription received:', data.text);
        
        // Add to live transcriptions for video overlay only
        setLiveTranscriptions(prev => {
          const newTranscriptions = [...prev, {
            id: Date.now(),
            text: data.text,
            timestamp: data.timestamp
          }];
          return newTranscriptions.slice(-3);
        });
        setShowTranscriptions(true);
      }
    });

    audioStreamService.onErrorOccurred((error) => {
      console.error('Audio stream error:', error);
      setIsStreamingAudio(false);
    });

    // Cleanup on unmount
    return () => {
      audioStreamService.disconnect();
      youtubeSyncService.disconnect();
    };
  }, [WEBINAR_VIDEO_ID, syncMode]);

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;
    
    const userMessage = input.trim();
    setInput("");
    setIsLoading(true);
    
    // Add user message immediately
    setMessages((msgs) => [
      ...msgs,
      { from: "user", text: userMessage },
    ]);
    
    try {
      // Query the backend directly
      const response = await fetch(`${process.env.REACT_APP_API_URL}/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text: userMessage }),
      });
      
      if (response.ok) {
        // Handle both JSON and text responses
        const contentType = response.headers.get('content-type');
        let aiResponse;
        
        if (contentType && contentType.includes('application/json')) {
          const data = await response.json();
          aiResponse = data.answer || data.response || JSON.stringify(data);
        } else {
          // Backend returns plain text
          aiResponse = await response.text();
        }
        
        setMessages((msgs) => [
          ...msgs,
          {
            from: "ai",
            text: aiResponse || "I received your message but couldn't generate a proper response.",
          },
        ]);
      } else {
        const errorText = await response.text();
        console.error('Backend error:', response.status, errorText);
        throw new Error(`HTTP ${response.status}: ${errorText}`);
      }
    } catch (error) {
      console.error('Error querying AI:', error);
      
      let errorMessage = "I encountered an error while processing your question.";
      
      if (error.message.includes('500')) {
        errorMessage = "The backend encountered an internal error. This might be due to the RAG pipeline or document processing. Please try a simpler question or try again later.";
      } else if (error.message.includes('404')) {
        errorMessage = "The query endpoint was not found. Please check the backend configuration.";
      } else if (serverStatus === 'disconnected') {
        errorMessage = "I'm having trouble connecting to the server. Please check your connection and try again.";
      }
      
      // Add error message
      setMessages((msgs) => [
        ...msgs,
        {
          from: "ai",
          text: errorMessage,
        },
      ]);
    } finally {
      setIsLoading(false);
      inputRef.current && inputRef.current.focus();
    }
  };

  // Function to open the debug player tab
  const openDebugPlayerTab = () => {
    // Use window.open directly to ensure we get the debug version
    const playerUrl = `${window.location.origin}/debug-player.html?videoId=${WEBINAR_VIDEO_ID}`;
    
    const debugWindow = window.open(
      playerUrl,
      'youtube-debug-player',
      'width=800,height=800,menubar=no,toolbar=no,location=no,status=no'
    );
    
    if (debugWindow) {
      console.log('🎬 DEBUG Player tab opened:', playerUrl);
      return true;
    } else {
      console.error('❌ Failed to open DEBUG player tab - popup blocked?');
      return false;
    }
  };

  const startVideo = () => {
    setPlaying(true);
    setChatOpen(true);
    
    // Automatically open player tab when video starts
    setTimeout(() => {
      const success = youtubeSyncService.openPlayerTab(WEBINAR_VIDEO_ID);
      
      if (!success) {
        console.warn('Failed to open player tab - popup may be blocked');
      }
    }, 500); // Small delay to ensure video has started
  };

  const startAudioStream = async () => {
    try {
      // Always use dual-tab mode
      if (!playerTabReady) {
        alert('Player tab is not ready yet. Please wait for the player tab to load, then try again.');
        return;
      }
      
      // Start audio capture in player tab
      youtubeSyncService.startAudioCapture();
      setIsStreamingAudio(true);
      setShowTranscriptions(true);
      
      console.log('🔊 Dual-tab audio streaming started');
    } catch (error) {
      console.error('Failed to start audio stream:', error);
      alert('Failed to start audio recording. Please ensure the player tab is open and try again.');
    }
  };

  const stopAudioStream = async () => {
    try {
      youtubeSyncService.stopAudioCapture();
      setIsStreamingAudio(false);
      console.log('🔊 Audio streaming stopped');
    } catch (error) {
      console.error('Failed to stop audio stream:', error);
    }
  };

  const toggleAudioStream = () => {
    if (isStreamingAudio) {
      stopAudioStream();
    } else {
      startAudioStream();
    }
  };

  return (
    <Page>
      <WebinarWrapper>
        <VideoSection>
          <VideoPlayer>
            {!playing && (
              <StartVideoButton
                aria-label="Start AI-Powered SaaS Demo"
                onClick={startVideo}
              >
                <RobotImage 
                  src="/robot-svgrepo-com_copie_2.png" 
                  alt="AI Robot"
                />
                <ButtonLabel>
                  Start AI Demo<br/>
                  Click to begin
                </ButtonLabel>
              </StartVideoButton>
            )}
            {playing && (
              <>
                {/* YouTube Video Player */}
                <YouTubeFrame
                  show={playing}
                  src={`https://www.youtube.com/embed/${WEBINAR_VIDEO_ID}?autoplay=1&modestbranding=1&rel=0`}
                  title="Marketing Webinar"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowFullScreen
                />
              

                {/* Live Transcription Display */}
                <LiveTranscription show={showTranscriptions && liveTranscriptions.length > 0}>
                  {liveTranscriptions.map((transcription, index) => (
                    <TranscriptionText key={transcription.id}>
                      {transcription.text}
                    </TranscriptionText>
                  ))}
                  {liveTranscriptions.length === 0 && showTranscriptions && (
                    <TranscriptionText style={{ opacity: 0.6 }}>
                      Click the speaker icon to start capturing audio from the video...
                    </TranscriptionText>
                  )}
                </LiveTranscription>

                {/* Video Controls */}
                <VideoControls>
                  <span>🔴 LIVE</span>
                  <span>•</span>
                  <span>AI-Powered SaaS Demo</span>
                </VideoControls>
              </>
            )}
          </VideoPlayer>
          
          <NeedHelpBanner>
            <span>🤖</span>
            <HelpText>
              Need help? Ask your AI assistant
              {playerTabReady && (
                <div style={{ fontSize: '0.9rem', color: '#22c55e', marginTop: '4px' }}>
                  🎬 Player tab ready - use recording controls in the player tab
                </div>
              )}
              {isStreamingAudio && (
                <div style={{ fontSize: '0.9rem', color: '#22c55e', marginTop: '4px' }}>
                  🔊 Audio capture active - check console for logs
                </div>
              )}
            </HelpText>
            {!chatOpen && (
              <StartButton onClick={() => setChatOpen(true)}>
                Start the conversation
              </StartButton>
            )}
          </NeedHelpBanner>
        </VideoSection>
        {(chatOpen || playing) && (
          <ChatSection>
            <ChatHeader>
              <AssistantName>AI Assistant</AssistantName>
              <AssistantDesc>
                Powered by AI – based on video & product data
                {isStreamingAudio && (
                  <span style={{ color: '#22c55e', marginLeft: '8px' }}>
                    🔊 Audio streaming from player tab
                  </span>
                )}
              </AssistantDesc>
              <StatusIndicator status={serverStatus}>
                <StatusDot status={serverStatus} />
                {serverStatus === 'connected' ? 'Connected' : 
                 serverStatus === 'disconnected' ? 'Offline' : 'Connecting...'}
              </StatusIndicator>
            </ChatHeader>
            <ChatBody ref={chatBodyRef}>
              {messages.map((msg, i) => (
                <MessageBubble
                  key={i}
                  from={msg.from}
                >
                  {msg.text}
                </MessageBubble>
              ))}
              {isLoading && (
                <MessageBubble from="ai">
                  AI is thinking...
                </MessageBubble>
              )}
            </ChatBody>
            <ChatFooter onSubmit={sendMessage}>
              <Input
                type="text"
                placeholder="Ask anything about the webinar or app"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                ref={inputRef}
                disabled={isLoading || serverStatus === 'disconnected'}
              />
              <SendBtn 
                type="submit" 
                disabled={isLoading || serverStatus === 'disconnected' || !input.trim()}
              >
                ➤
              </SendBtn>
            </ChatFooter>
          </ChatSection>
        )}
      </WebinarWrapper>
    </Page>
  );
};

export default AnnaWebinarFixed;

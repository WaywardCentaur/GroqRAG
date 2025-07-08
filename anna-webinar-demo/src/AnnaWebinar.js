import React, { useState, useRef, useEffect } from "react";
import styled from "styled-components";
import apiService from './apiService';
import audioStreamService from './audioStreamService';

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
`;

const AudioControls = styled.div`
  position: absolute;
  bottom: 50px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 12px;
  align-items: center;
  background: rgba(0, 0, 0, 0.7);
  padding: 8px 16px;
  border-radius: 25px;
  backdrop-filter: blur(10px);s
`;

const AudioButton = styled.button`
  background: ${({ active, disabled }) => 
    disabled ? '#6b7280' : 
    active ? '#ef4444' : '#22c55e'};
  color: white;
  border: none;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: ${({ disabled }) => disabled ? 'not-allowed' : 'pointer'};
  font-size: 14px;
  font-weight: 600;
  transition: all 0.2s;

  &:hover {
    transform: ${({ disabled }) => disabled ? 'none' : 'scale(1.05)'};
  }
`;

const LiveTranscription = styled.div`
  position: absolute;
  bottom: 16px;
  left: 16px;
  right: 16px;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 0.9rem;
  max-height: 80px;
  overflow-y: auto;
  backdrop-filter: blur(10px);
  display: ${({ show }) => show ? 'block' : 'none'};
`;

const TranscriptionText = styled.div`
  line-height: 1.4;
  
  &:not(:last-child) {
    margin-bottom: 8px;
    opacity: 0.7;
  }
`;

const PlayButton = styled.button`
  border: none;
  background: none;
  cursor: pointer;
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
`;

const PlayIcon = () => (
  <svg width="64" height="64" fill="none">
    <circle cx="32" cy="32" r="32" fill="#3E4A63" opacity="0.6"/>
    <polygon points="26,22 48,32 26,42" fill="#fff"/>
  </svg>
);

const VideoLabel = styled.div`
  color: #f5f7fa;
  font-size: 1.2rem;
  font-weight: 600;
  margin-top: 100px;
  text-align: center;
`;

const VideoControls = styled.div`
  width: 100%;
  display: flex;
  align-items: center;
  margin-top: 150px;
  justify-content: space-between;
  padding: 0 24px 16px 24px;
  box-sizing: border-box;
  color: #a8adc1;
  font-size: 0.95rem;
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

  @media (max-width: 600px) {
    flex-direction: column;
    gap: 8px;
    padding: 12px;
  }
`;

const AssistantIcon = styled.span`
  width: 36px;
  height: 36px;
  display: inline-block;
  background: url("https://img.icons8.com/ios-filled/50/robot-2.png");
  background-size: contain;
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

  @media (max-width: 900px) {
    max-width: 100vw;
    min-width: 0;
    margin: 0 auto;
  }
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

const LoadingMessage = styled.div`
  background: #f3f5fa;
  color: #7b7f91;
  padding: 11px 16px;
  border-radius: 13px;
  max-width: 80%;
  align-self: flex-start;
  font-size: 0.97rem;
  font-style: italic;
  display: flex;
  align-items: center;
  gap: 8px;
`;

const LoadingDots = styled.div`
  display: flex;
  gap: 2px;
  
  div {
    width: 4px;
    height: 4px;
    background: #7b7f91;
    border-radius: 50%;
    animation: loading 1.4s infinite ease-in-out;
  }
  
  div:nth-child(1) { animation-delay: -0.32s; }
  div:nth-child(2) { animation-delay: -0.16s; }
  
  @keyframes loading {
    0%, 80%, 100% { opacity: 0.3; }
    40% { opacity: 1; }
  }
`;

// --- Main Component ---

const AnnaWebinar = () => {
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
  const [isStreamingAudio, setIsStreamingAudio] = useState(false);
  const [audioStreamConnected, setAudioStreamConnected] = useState(false);
  const [showTranscriptions, setShowTranscriptions] = useState(false);
  const [liveTranscriptions, setLiveTranscriptions] = useState([]);
  const inputRef = useRef(null);
  const videoRef = useRef(null);

  // Auto-scroll chat to bottom
  const chatBodyRef = useRef(null);
  useEffect(() => {
    if (chatBodyRef.current) {
      chatBodyRef.current.scrollTop = chatBodyRef.current.scrollHeight;
    }
  }, [messages, chatOpen]);

  // Check server health on component mount
  useEffect(() => {
    const checkServerHealth = async () => {
      try {
        const isHealthy = await apiService.checkHealth();
        setServerStatus(isHealthy ? 'connected' : 'disconnected');
      } catch (error) {
        setServerStatus('disconnected');
      }
    };

    checkServerHealth();
    const interval = setInterval(checkServerHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  // Set up audio stream service
  useEffect(() => {
    audioStreamService.onConnectionChanged((connected) => {
      setAudioStreamConnected(connected);
    });

    audioStreamService.onTranscriptionReceived((data) => {
      console.log('📝 New transcription:', data.text);
      
      setLiveTranscriptions(prev => {
        const newTranscriptions = [...prev, {
          id: Date.now(),
          text: data.text,
          timestamp: data.timestamp
        }];
        return newTranscriptions.slice(-3);
      });

      setShowTranscriptions(true);
      
      if (chatOpen) {
        setMessages(prev => [...prev, {
          from: "transcription",
          text: "🎤 Live: " + data.text,
          timestamp: data.timestamp
        }]);
      }
    });

    audioStreamService.onErrorOccurred((error) => {
      console.error('Audio stream error:', error);
      setIsStreamingAudio(false);
    });

    return () => {
      audioStreamService.disconnect();
    };
  }, [chatOpen]);

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;
    
    const userMessage = input.trim();
    setInput("");
    setIsLoading(true);
    
    setMessages((msgs) => [
      ...msgs,
      { from: "user", text: userMessage },
    ]);
    
    try {
      const answer = await apiService.query(userMessage);
      
      setMessages((msgs) => [
        ...msgs,
        {
          from: "ai",
          text: answer || "I apologize, but I couldn't generate a response at this time. Please try again.",
        },
      ]);
    } catch (error) {
      console.error('Error querying AI:', error);
      
      setMessages((msgs) => [
        ...msgs,
        {
          from: "ai",
          text: serverStatus === 'disconnected' 
            ? "I'm having trouble connecting to the server. Please check your connection and try again."
            : "I encountered an error while processing your question. Please try again.",
        },
      ]);
    } finally {
      setIsLoading(false);
      inputRef.current && inputRef.current.focus();
    }
  };

  const toggleAudioStreaming = async () => {
    if (isStreamingAudio) {
      audioStreamService.stopRecording();
      setIsStreamingAudio(false);
      console.log('🛑 Audio streaming stopped');
    } else {
      if (playing && videoRef.current) {
        const success = await audioStreamService.startVideoAudioStreaming(videoRef.current);
        if (success) {
          setIsStreamingAudio(true);
          console.log('🎵 Video audio streaming started');
        }
      } else {
        const success = await audioStreamService.startMicrophoneRecording();
        if (success) {
          setIsStreamingAudio(true);
          console.log('🎤 Microphone streaming started');
        }
      }
    }
  };

  const toggleTranscriptionDisplay = () => {
    setShowTranscriptions(!showTranscriptions);
  };

  const startVideo = () => {
    setPlaying(true);
    setChatOpen(true);
    
    setTimeout(() => {
      if (videoRef.current && serverStatus === 'connected') {
        toggleAudioStreaming();
      }
    }, 1000);
  };

  return (
    <Page>
      <WebinarWrapper>
        <VideoSection>
          <VideoPlayer>
            {!playing && (
              <>
                <PlayButton
                  aria-label="Play"
                  onClick={startVideo}
                >
                  <PlayIcon />
                </PlayButton>
                <VideoLabel>AI-Powered SaaS Demo<br/>Click to play webinar</VideoLabel>
              </>
            )}
            {playing && (
              <>
                <VideoElement
                  ref={videoRef}
                  crossOrigin="anonymous"
                  style={{ display: 'none' }}
                />
                <VideoLabel>AI-Powered SaaS Demo<br/>[Livestream playing]</VideoLabel>
                <VideoControls>
                  <div>12:34 / 45:07</div>
                  <div>
                    <svg width="20" height="20" fill="#ea4a4a"><circle cx="10" cy="10" r="6"/></svg> LIVE
                  </div>
                </VideoControls>
                
                <AudioControls>
                  <AudioButton
                    onClick={toggleAudioStreaming}
                    active={isStreamingAudio}
                    disabled={serverStatus !== 'connected'}
                    title={isStreamingAudio ? "Stop Audio Streaming" : "Start Audio Streaming"}
                  >
                    {isStreamingAudio ? "🛑" : "🎤"}
                  </AudioButton>
                  
                  <AudioButton
                    onClick={toggleTranscriptionDisplay}
                    active={showTranscriptions}
                    title="Toggle Live Transcriptions"
                  >
                    📝
                  </AudioButton>
                  
                  {audioStreamConnected && (
                    <div style={{ color: '#22c55e', fontSize: '12px', fontWeight: 'bold' }}>
                      LIVE
                    </div>
                  )}
                </AudioControls>

                <LiveTranscription show={showTranscriptions && liveTranscriptions.length > 0}>
                  {liveTranscriptions.map((transcription) => (
                    <TranscriptionText key={transcription.id}>
                      {transcription.text}
                    </TranscriptionText>
                  ))}
                </LiveTranscription>
              </>
            )}
          </VideoPlayer>
          <NeedHelpBanner>
            <AssistantIcon />
            <HelpText>Need help? Ask your AI assistant</HelpText>
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
              <AssistantDesc>Powered by AI – based on video & product data</AssistantDesc>
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
                <LoadingMessage>
                  AI is thinking
                  <LoadingDots>
                    <div></div>
                    <div></div>
                    <div></div>
                  </LoadingDots>
                </LoadingMessage>
              )}
            </ChatBody>
            <ChatFooter
              onSubmit={sendMessage}
              aria-label="Ask the assistant a question"
            >
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
                <svg width="20" height="20" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 17L17 10L3 3V10L17 10"/></svg>
              </SendBtn>
            </ChatFooter>
          </ChatSection>
        )}
      </WebinarWrapper>
    </Page>
  );
};

export default AnnaWebinar;
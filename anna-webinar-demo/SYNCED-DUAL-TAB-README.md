# Anna Webinar Demo - Synchronized Dual Tab System

## Overview

This is a synchronized dual-tab system where **both tabs play the same YouTube video simultaneously** while maintaining separate functions:

- **Main Tab**: Video player + AI chat + transcription overlay
- **Player Tab**: Video player + audio capture (NO CHAT)

## Key Features

### ✅ Synchronized Video Playback
- Both tabs play the same YouTube video at the same time
- Videos start simultaneously when you click "Start Video"
- Both videos use optimized parameters for sync

### ✅ Dedicated Functions
- **Main Tab**: User interface, AI chat, video viewing, transcription overlay
- **Player Tab**: Audio capture only, no chat interface

### ✅ Audio Capture & Transcription
- Audio is captured from the player tab only
- Transcriptions appear on both tabs
- Real-time audio streaming to backend

### ✅ Clean Architecture
- No UI conflicts between tabs
- Robust error handling
- Clear status indicators

## How to Start

```bash
./start-synced-dual-tab.sh
```

## User Workflow

1. **Start**: Click "▶️ Start Video" in the main tab
2. **Sync**: Video starts playing in main tab
3. **Auto-Open**: Player tab opens automatically with synchronized video
4. **Audio**: In player tab, click "🎤 Start Audio Capture"
5. **Permissions**: Allow screen sharing and check "Share tab audio"
6. **Chat**: Return to main tab to chat with Anna AI
7. **Transcriptions**: See live transcriptions on both tabs

## Technical Implementation

### Video Synchronization
Both tabs load the same YouTube video with:
- `autoplay=1` for immediate start
- Timestamp parameter for fresh loads
- Optimized parameters for sync
- Same video ID and starting point

### Tab Communication
- Uses `BroadcastChannel` API for cross-tab messaging
- Player tab sends transcriptions to main tab
- Status updates between tabs
- Error handling and reconnection

### Audio Processing
- Player tab captures tab audio using `getDisplayMedia()`
- Audio chunks sent to backend via WebSocket
- Real-time transcription processing
- Transcriptions distributed to both tabs

## File Structure

```
src/
├── AnnaWebinarDualTabSynced.js  # Main synchronized component
├── youtubeSyncService.js        # Enhanced tab communication
├── audioStreamService.js        # Audio capture & streaming
└── apiService.js               # Backend API communication

public/
├── youtube-player-clean.html    # Synchronized player tab
├── debug-player.html           # Debug version with logging
└── index.html                  # Main app entry
```

## Status Indicators

### Main Tab
- **Backend**: AI backend connection status
- **Player Tab**: Whether player tab is ready
- **Audio**: Whether audio is streaming from player tab

### Player Tab
- **Connection**: Link status to main tab
- **Audio Status**: Current audio capture state
- **Video**: YouTube video load status

## Benefits

1. **True Dual Experience**: Both tabs show the video, maintaining context
2. **Specialized Functions**: Each tab has a clear, dedicated purpose
3. **Synchronized Playback**: Videos start and play together
4. **No UI Conflicts**: Player tab never shows chat interface
5. **Better User Experience**: Users can watch in main tab while audio captures in background

## Troubleshooting

### Video Not Playing
- Check if popups are blocked
- Ensure both tabs load completely
- Try refreshing both tabs

### Audio Capture Issues
- Make sure to select "This Tab" in browser dialog
- **Critical**: Check "Share tab audio" checkbox
- Use Chrome browser for best compatibility
- Check microphone permissions

### Sync Issues
- Both videos should start within 1-2 seconds of each other
- If out of sync, refresh the player tab
- Check browser console for sync messages

## Environment Setup

Required in `.env.development`:
```
PORT=3000
REACT_APP_API_URL=http://149.28.123.26:8000
REACT_APP_WS_URL=ws://149.28.123.26:8000
REACT_APP_ENV=development
BROWSER=none
```

## Comparison with Previous Systems

### vs Single Tab
- ✅ No audio capture interference with main UI
- ✅ Better performance separation
- ✅ Users can focus on chat while audio captures

### vs Non-Synchronized Dual Tab
- ✅ User sees video content in main interface
- ✅ Maintains video context for AI chat
- ✅ Better user experience - no "black screen" confusion

This synchronized approach provides the best of both worlds: clean separation of concerns with synchronized video playback for the best user experience.

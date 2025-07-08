# Anna Webinar Demo - Dual Tab System

## Overview

This is a rebuilt dual-tab system for the Anna Webinar Demo that provides clean separation between video playback/audio capture and AI chat functionality.

## Architecture

### Main Tab (`AnnaWebinarDualTab.js`)
- **Purpose**: Primary user interface with video controls and AI chat
- **Features**:
  - Video player with play/stop controls
  - AI chat interface with Anna
  - Transcription overlay on video
  - Control panel with status indicators
  - Automatic player tab management

### Player Tab (`youtube-player-clean.html`)
- **Purpose**: Dedicated YouTube video playback and audio capture
- **Features**:
  - YouTube video embedding with autoplay
  - Audio capture controls
  - Local transcription display
  - **NO CHAT INTERFACE** (prevents confusion)
  - Clear instructions for audio capture

## Key Improvements

### 1. Clean Separation
- Main tab handles UI and chat
- Player tab handles only video and audio
- No cross-contamination of UI elements

### 2. Robust Communication
- Uses `youtubeSyncService` for tab-to-tab communication
- Simplified message format without problematic parameters
- Better error handling and logging

### 3. User Experience
- Clear instructions in both tabs
- Visual status indicators
- Automatic tab management
- Better error messages

### 4. Technical Fixes
- Removed problematic `show` parameter handling
- Unique transcription IDs prevent React key issues
- Consistent data types across tabs
- Prevention of chat UI in player tab

## How to Use

### Starting the System
```bash
./start-dual-tab.sh
```

### User Workflow
1. **Main Tab**: Click "Start Video" button
2. **Player Tab**: Opens automatically with YouTube video
3. **Player Tab**: Click "Start Audio Capture" and follow browser prompts
4. **Main Tab**: Chat with Anna AI while transcriptions appear
5. **Both Tabs**: Monitor status indicators for connection health

### Audio Capture Setup
When starting audio capture in the player tab:
1. Browser will show a screen sharing dialog
2. **Select "This Tab"**
3. **Check "Share tab audio"** (critical!)
4. Click "Share"
5. Audio from YouTube will be captured and transcribed

## File Structure

```
src/
├── AnnaWebinarDualTab.js     # Main component (new)
├── youtubeSyncService.js     # Tab communication (updated)
├── audioStreamService.js     # Audio handling
└── apiService.js             # Backend API

public/
├── youtube-player-clean.html # Player tab (new)
├── debug-player.html         # Debug version
└── index.html               # Main app entry
```

## Status Indicators

### Main Tab
- **Backend**: Connection to AI backend
- **Player Tab**: Whether player tab is ready
- **Audio**: Whether audio is streaming from player tab

### Player Tab
- **Connection**: Link to main tab
- **Audio Status**: Current audio capture state
- **Transcriptions**: Local view of transcriptions

## Debugging

### Debug Mode
- Debug button available in development mode
- Opens enhanced player tab with detailed logging
- Shows all message passing between tabs

### Common Issues
1. **Popup Blocked**: Allow popups for the site
2. **No Audio**: Ensure "Share tab audio" is checked
3. **Backend Offline**: Check API server status
4. **Tab Communication**: Check browser console for sync messages

## Environment Variables

Required in `.env.development`:
```
PORT=3000
REACT_APP_API_URL=http://149.28.123.26:8000
REACT_APP_WS_URL=ws://149.28.123.26:8000
REACT_APP_ENV=development
BROWSER=none
```

## Benefits of This Approach

1. **No UI Conflicts**: Player tab can never show chat interface
2. **Better Performance**: Each tab handles specific responsibilities
3. **Cleaner Code**: Separation of concerns improves maintainability
4. **Better UX**: Clear purpose for each tab reduces user confusion
5. **Robust Error Handling**: Better feedback when things go wrong

## Migration from Old System

The old `AnnaWebinarFixed.js` is preserved for reference, but the new `AnnaWebinarDualTab.js` is now the default. Key differences:

- Removed complex single/dual tab mode switching
- Simplified state management
- Cleaner player tab without React components
- Better error boundaries and status reporting

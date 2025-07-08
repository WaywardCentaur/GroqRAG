# React Integration Guide for Audio RAG Agent

This guide shows how to integrate your Audio RAG Agent with a React frontend application.

## 📋 Table of Contents

1. [API Endpoints Overview](#api-endpoints-overview)
2. [HTTP Client Setup](#http-client-setup)
3. [Document Management](#document-management)
4. [Transcription Management](#transcription-management)
5. [Audio Recording & WebSocket](#audio-recording--websocket)
6. [Query Interface](#query-interface)
7. [Error Handling](#error-handling)
8. [Complete React Components](#complete-react-components)

## 🌐 API Endpoints Overview

Your Audio RAG Agent provides these endpoints:

```typescript
// Base URL (adjust for your deployment)
const API_BASE_URL = 'http://149.28.123.26:8000';
const WS_BASE_URL = 'ws://149.28.123.26:8000';

// HTTP Endpoints
GET    /health                           // Health check
POST   /query                           // RAG query
GET    /documents                       // List documents
POST   /documents                       // Upload document
DELETE /documents/{document_id}         // Delete document
GET    /transcriptions                  // List transcriptions
DELETE /transcriptions/{transcription_id} // Delete transcription

// WebSocket Endpoints
WS     /audio                           // Audio streaming
```

## 🔧 HTTP Client Setup

### Install Dependencies

```bash
npm install axios
# or
yarn add axios
```

### API Client Configuration

```typescript
// src/services/api.ts
import axios, { AxiosResponse } from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://149.28.123.26:8000';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    throw error;
  }
);

// Types
export interface Document {
  id: string;
  filename: string;
  content_preview: string;
  upload_time: string;
  file_size?: number;
  file_type?: string;
}

export interface Transcription {
  id: string;
  text: string;
  timestamp: string;
  duration?: number;
}

export interface QueryResponse {
  response: string;
  sources: Array<{
    content: string;
    metadata: Record<string, any>;
  }>;
  processing_time: number;
}
```

## 📄 Document Management

### Document Service

```typescript
// src/services/documentService.ts
import { apiClient, Document } from './api';

export class DocumentService {
  // List all documents
  static async getDocuments(): Promise<Document[]> {
    const response = await apiClient.get<Document[]>('/documents');
    return response.data;
  }

  // Upload a document
  static async uploadDocument(file: File): Promise<Document> {
    const formData = new FormData();
    formData.append('file', file);

    const response = await apiClient.post<Document>('/documents', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  }

  // Delete a document
  static async deleteDocument(documentId: string): Promise<void> {
    await apiClient.delete(`/documents/${documentId}`);
  }
}
```

### React Document Component

```tsx
// src/components/DocumentManager.tsx
import React, { useState, useEffect } from 'react';
import { DocumentService, Document } from '../services/documentService';

export const DocumentManager: React.FC = () => {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [uploading, setUploading] = useState(false);
  const [loading, setLoading] = useState(true);

  // Load documents on component mount
  useEffect(() => {
    loadDocuments();
  }, []);

  const loadDocuments = async () => {
    try {
      setLoading(true);
      const docs = await DocumentService.getDocuments();
      setDocuments(docs);
    } catch (error) {
      console.error('Failed to load documents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setUploading(true);
      await DocumentService.uploadDocument(file);
      await loadDocuments(); // Refresh the list
      
      // Reset file input
      event.target.value = '';
    } catch (error) {
      console.error('Failed to upload document:', error);
      alert('Failed to upload document. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (documentId: string, filename: string) => {
    if (!window.confirm(`Are you sure you want to delete "${filename}"?`)) {
      return;
    }

    try {
      await DocumentService.deleteDocument(documentId);
      await loadDocuments(); // Refresh the list
    } catch (error) {
      console.error('Failed to delete document:', error);
      alert('Failed to delete document. Please try again.');
    }
  };

  if (loading) return <div>Loading documents...</div>;

  return (
    <div className="document-manager">
      <h2>Document Management</h2>
      
      {/* Upload Section */}
      <div className="upload-section">
        <input
          type="file"
          accept=".pdf,.txt,.doc,.docx"
          onChange={handleFileUpload}
          disabled={uploading}
        />
        {uploading && <span>Uploading...</span>}
      </div>

      {/* Documents Table */}
      <table className="documents-table">
        <thead>
          <tr>
            <th>Filename</th>
            <th>Preview</th>
            <th>Upload Time</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {documents.map((doc) => (
            <tr key={doc.id}>
              <td>{doc.filename}</td>
              <td>{doc.content_preview}</td>
              <td>{new Date(doc.upload_time).toLocaleString()}</td>
              <td>
                <button
                  onClick={() => handleDelete(doc.id, doc.filename)}
                  className="delete-btn"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
```

## 🎤 Transcription Management

### Transcription Service

```typescript
// src/services/transcriptionService.ts
import { apiClient, Transcription } from './api';

export class TranscriptionService {
  // List all transcriptions
  static async getTranscriptions(): Promise<Transcription[]> {
    const response = await apiClient.get<Transcription[]>('/transcriptions');
    return response.data;
  }

  // Delete a transcription
  static async deleteTranscription(transcriptionId: string): Promise<void> {
    await apiClient.delete(`/transcriptions/${transcriptionId}`);
  }
}
```

### React Transcription Component

```tsx
// src/components/TranscriptionManager.tsx
import React, { useState, useEffect } from 'react';
import { TranscriptionService, Transcription } from '../services/transcriptionService';

export const TranscriptionManager: React.FC = () => {
  const [transcriptions, setTranscriptions] = useState<Transcription[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadTranscriptions();
  }, []);

  const loadTranscriptions = async () => {
    try {
      setLoading(true);
      const transcripts = await TranscriptionService.getTranscriptions();
      setTranscriptions(transcripts);
    } catch (error) {
      console.error('Failed to load transcriptions:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (transcriptionId: string) => {
    if (!window.confirm('Are you sure you want to delete this transcription?')) {
      return;
    }

    try {
      await TranscriptionService.deleteTranscription(transcriptionId);
      await loadTranscriptions(); // Refresh the list
    } catch (error) {
      console.error('Failed to delete transcription:', error);
      alert('Failed to delete transcription. Please try again.');
    }
  };

  if (loading) return <div>Loading transcriptions...</div>;

  return (
    <div className="transcription-manager">
      <h2>Transcription Management</h2>
      
      <table className="transcriptions-table">
        <thead>
          <tr>
            <th>Text</th>
            <th>Timestamp</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {transcriptions.map((transcript) => (
            <tr key={transcript.id}>
              <td>{transcript.text}</td>
              <td>{new Date(transcript.timestamp).toLocaleString()}</td>
              <td>
                <button
                  onClick={() => handleDelete(transcript.id)}
                  className="delete-btn"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
```

## 🎵 Audio Recording & WebSocket

### Audio Recording Hook

```typescript
// src/hooks/useAudioRecording.ts
import { useState, useRef, useCallback } from 'react';

interface AudioRecordingHook {
  isRecording: boolean;
  startRecording: () => Promise<void>;
  stopRecording: () => void;
  transcription: string;
  error: string | null;
}

export const useAudioRecording = (
  wsUrl: string = 'ws://149.28.123.26:8000/audio'
): AudioRecordingHook => {
  const [isRecording, setIsRecording] = useState(false);
  const [transcription, setTranscription] = useState('');
  const [error, setError] = useState<string | null>(null);
  
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const websocketRef = useRef<WebSocket | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const startRecording = useCallback(async () => {
    try {
      setError(null);
      setTranscription('');

      // Get user media
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: 16000,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true,
        },
      });
      streamRef.current = stream;

      // Setup WebSocket
      const ws = new WebSocket(wsUrl);
      websocketRef.current = ws;

      ws.onopen = () => {
        console.log('WebSocket connected');
        setIsRecording(true);
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          
          if (data.type === 'transcription') {
            setTranscription(data.text);
          } else if (data.type === 'error') {
            setError(data.message);
          }
        } catch (err) {
          console.error('Failed to parse WebSocket message:', err);
        }
      };

      ws.onerror = (event) => {
        console.error('WebSocket error:', event);
        setError('WebSocket connection failed');
      };

      ws.onclose = () => {
        console.log('WebSocket disconnected');
        setIsRecording(false);
      };

      // Setup MediaRecorder
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus',
      });
      mediaRecorderRef.current = mediaRecorder;

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0 && ws.readyState === WebSocket.OPEN) {
          // Convert blob to array buffer and send
          event.data.arrayBuffer().then((arrayBuffer) => {
            ws.send(arrayBuffer);
          });
        }
      };

      // Start recording with small chunks for real-time processing
      mediaRecorder.start(250); // Send data every 250ms

    } catch (err) {
      console.error('Failed to start recording:', err);
      setError('Failed to access microphone');
    }
  }, [wsUrl]);

  const stopRecording = useCallback(() => {
    if (mediaRecorderRef.current) {
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current = null;
    }

    if (websocketRef.current) {
      websocketRef.current.close();
      websocketRef.current = null;
    }

    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }

    setIsRecording(false);
  }, []);

  return {
    isRecording,
    startRecording,
    stopRecording,
    transcription,
    error,
  };
};
```

### Audio Recording Component

```tsx
// src/components/AudioRecorder.tsx
import React from 'react';
import { useAudioRecording } from '../hooks/useAudioRecording';

interface AudioRecorderProps {
  wsUrl?: string;
  onTranscriptionComplete?: (text: string) => void;
}

export const AudioRecorder: React.FC<AudioRecorderProps> = ({
  wsUrl = 'ws://149.28.123.26:8000/audio',
  onTranscriptionComplete,
}) => {
  const {
    isRecording,
    startRecording,
    stopRecording,
    transcription,
    error,
  } = useAudioRecording(wsUrl);

  React.useEffect(() => {
    if (transcription && onTranscriptionComplete) {
      onTranscriptionComplete(transcription);
    }
  }, [transcription, onTranscriptionComplete]);

  return (
    <div className="audio-recorder">
      <h3>Audio Recording</h3>
      
      <div className="recording-controls">
        {!isRecording ? (
          <button onClick={startRecording} className="start-btn">
            🎤 Start Recording
          </button>
        ) : (
          <button onClick={stopRecording} className="stop-btn">
            ⏹️ Stop Recording
          </button>
        )}
      </div>

      {isRecording && (
        <div className="recording-status">
          <span className="recording-indicator">🔴 Recording...</span>
        </div>
      )}

      {error && (
        <div className="error-message">
          ❌ Error: {error}
        </div>
      )}

      {transcription && (
        <div className="transcription-result">
          <h4>Transcription:</h4>
          <p>{transcription}</p>
        </div>
      )}
    </div>
  );
};
```

## 🔍 Query Interface

### Query Service

```typescript
// src/services/queryService.ts
import { apiClient, QueryResponse } from './api';

export class QueryService {
  static async query(text: string): Promise<QueryResponse> {
    const response = await apiClient.post<QueryResponse>('/query', {
      text: text.trim(),
    });
    return response.data;
  }
}
```

### Query Component

```tsx
// src/components/QueryInterface.tsx
import React, { useState } from 'react';
import { QueryService, QueryResponse } from '../services/queryService';
import { AudioRecorder } from './AudioRecorder';

export const QueryInterface: React.FC = () => {
  const [query, setQuery] = useState('');
  const [response, setResponse] = useState<QueryResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [useAudio, setUseAudio] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;

    try {
      setLoading(true);
      const result = await QueryService.query(query);
      setResponse(result);
    } catch (error) {
      console.error('Query failed:', error);
      alert('Query failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleAudioTranscription = (text: string) => {
    setQuery(text);
    setUseAudio(false); // Switch back to text input after transcription
  };

  return (
    <div className="query-interface">
      <h2>RAG Query Interface</h2>
      
      <div className="input-method-toggle">
        <label>
          <input
            type="radio"
            checked={!useAudio}
            onChange={() => setUseAudio(false)}
          />
          Text Input
        </label>
        <label>
          <input
            type="radio"
            checked={useAudio}
            onChange={() => setUseAudio(true)}
          />
          Audio Input
        </label>
      </div>

      {useAudio ? (
        <AudioRecorder onTranscriptionComplete={handleAudioTranscription} />
      ) : (
        <form onSubmit={handleSubmit}>
          <div className="query-input">
            <textarea
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Enter your question..."
              rows={4}
              disabled={loading}
            />
          </div>
          <button type="submit" disabled={loading || !query.trim()}>
            {loading ? 'Processing...' : 'Submit Query'}
          </button>
        </form>
      )}

      {response && (
        <div className="query-response">
          <h3>Response:</h3>
          <p>{response.response}</p>
          
          {response.sources.length > 0 && (
            <div className="sources">
              <h4>Sources:</h4>
              {response.sources.map((source, index) => (
                <div key={index} className="source">
                  <p><strong>Source {index + 1}:</strong></p>
                  <p>{source.content}</p>
                </div>
              ))}
            </div>
          )}
          
          <p><small>Processing time: {response.processing_time.toFixed(2)}s</small></p>
        </div>
      )}
    </div>
  );
};
```

## ❌ Error Handling

### Global Error Handler

```typescript
// src/utils/errorHandler.ts
export class APIError extends Error {
  constructor(
    message: string,
    public status?: number,
    public details?: any
  ) {
    super(message);
    this.name = 'APIError';
  }
}

export const handleAPIError = (error: any): never => {
  if (error.response) {
    // Server responded with error status
    const status = error.response.status;
    const message = error.response.data?.detail || error.response.data?.message || 'Server error';
    throw new APIError(message, status, error.response.data);
  } else if (error.request) {
    // Network error
    throw new APIError('Network error - please check your connection');
  } else {
    // Other error
    throw new APIError(error.message || 'Unknown error occurred');
  }
};
```

### Error Boundary Component

```tsx
// src/components/ErrorBoundary.tsx
import React, { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <h2>Something went wrong!</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => window.location.reload()}>
            Reload Page
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

## 🎯 Complete React App Example

### Main App Component

```tsx
// src/App.tsx
import React, { useState } from 'react';
import { ErrorBoundary } from './components/ErrorBoundary';
import { DocumentManager } from './components/DocumentManager';
import { TranscriptionManager } from './components/TranscriptionManager';
import { QueryInterface } from './components/QueryInterface';
import './App.css';

type TabType = 'query' | 'documents' | 'transcriptions';

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('query');

  return (
    <ErrorBoundary>
      <div className="app">
        <header>
          <h1>Audio RAG Agent</h1>
          <nav>
            <button
              className={activeTab === 'query' ? 'active' : ''}
              onClick={() => setActiveTab('query')}
            >
              Query
            </button>
            <button
              className={activeTab === 'documents' ? 'active' : ''}
              onClick={() => setActiveTab('documents')}
            >
              Documents
            </button>
            <button
              className={activeTab === 'transcriptions' ? 'active' : ''}
              onClick={() => setActiveTab('transcriptions')}
            >
              Transcriptions
            </button>
          </nav>
        </header>

        <main>
          {activeTab === 'query' && <QueryInterface />}
          {activeTab === 'documents' && <DocumentManager />}
          {activeTab === 'transcriptions' && <TranscriptionManager />}
        </main>
      </div>
    </ErrorBoundary>
  );
};

export default App;
```

### Environment Configuration

```bash
# .env
REACT_APP_API_URL=http://149.28.123.26:8000
REACT_APP_WS_URL=ws://149.28.123.26:8000

# .env.production (if using domain later)
REACT_APP_API_URL=https://your-domain.com
REACT_APP_WS_URL=wss://your-domain.com
```

### Basic CSS Styles

```css
/* src/App.css */
.app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

header {
  border-bottom: 1px solid #ccc;
  margin-bottom: 20px;
  padding-bottom: 20px;
}

nav button {
  margin-right: 10px;
  padding: 10px 20px;
  border: 1px solid #ccc;
  background: white;
  cursor: pointer;
}

nav button.active {
  background: #007bff;
  color: white;
}

.documents-table,
.transcriptions-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
}

.documents-table th,
.documents-table td,
.transcriptions-table th,
.transcriptions-table td {
  border: 1px solid #ccc;
  padding: 10px;
  text-align: left;
}

.delete-btn {
  background: #dc3545;
  color: white;
  border: none;
  padding: 5px 10px;
  cursor: pointer;
  border-radius: 3px;
}

.audio-recorder {
  border: 1px solid #ccc;
  padding: 20px;
  margin: 20px 0;
  border-radius: 5px;
}

.recording-indicator {
  color: red;
  font-weight: bold;
}

.error-message {
  color: red;
  padding: 10px;
  background: #ffe6e6;
  border-radius: 3px;
}

.query-response {
  margin-top: 20px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 5px;
}

.sources {
  margin-top: 15px;
}

.source {
  margin-bottom: 10px;
  padding: 10px;
  background: white;
  border-radius: 3px;
}
```

## 🚀 Deployment Notes

1. **Environment Variables**: Set `REACT_APP_API_URL` and `REACT_APP_WS_URL` to your Vultr server URLs
2. **CORS**: Ensure your server's `CORS_ORIGINS` includes your React app's domain
3. **WebSocket**: Use `wss://` for HTTPS deployments
4. **Build**: Run `npm run build` and serve the build folder via Nginx or similar

This guide provides a complete foundation for integrating your Audio RAG Agent with a React frontend application!

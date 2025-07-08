// Configuration for the Anna Webinar Demo
const config = {
  // API base URL - update this based on your environment
  API_BASE_URL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
  
  // WebSocket URL for real-time audio processing
  WS_BASE_URL: process.env.REACT_APP_WS_URL || 'ws://localhost:8000',
  
  // Default endpoints
  endpoints: {
    query: '/query',
    documents: '/documents',
    health: '/health',
    transcriptions: '/transcriptions',
    audio: '/audio'
  }
};

// Debug logging
console.log('🔧 Config loaded:');
console.log('  - API_BASE_URL:', config.API_BASE_URL);
console.log('  - WS_BASE_URL:', config.WS_BASE_URL);
console.log('  - Environment variables:');
console.log('    - REACT_APP_API_URL:', process.env.REACT_APP_API_URL);
console.log('    - REACT_APP_WS_URL:', process.env.REACT_APP_WS_URL);

export default config;

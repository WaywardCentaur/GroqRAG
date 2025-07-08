import React from 'react';

const TestComponent = () => {
  return (
    <div style={{ padding: '20px', background: '#f0f0f0' }}>
      <h1>Anna Webinar Demo - Test Component</h1>
      <p>This is a test to verify basic React functionality.</p>
      <p>Environment: {process.env.REACT_APP_ENV}</p>
      <p>API URL: {process.env.REACT_APP_API_URL}</p>
      <p>WebSocket URL: {process.env.REACT_APP_WS_URL}</p>
    </div>
  );
};

export default TestComponent;

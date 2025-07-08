import React, { useState, useEffect } from 'react';
import styled from 'styled-components';

const Container = styled.div`
  min-height: 100vh;
  background: #343946;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
`;

const Content = styled.div`
  text-align: center;
  padding: 2rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
`;

const TestButton = styled.button`
  background: #6a5cff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  margin: 5px;
  cursor: pointer;
  
  &:hover {
    background: #5240ff;
  }
`;

const StatusIndicator = styled.div`
  margin: 10px 0;
  padding: 10px;
  border-radius: 5px;
  background: ${props => props.status === 'connected' ? '#22c55e' : 
                        props.status === 'disconnected' ? '#ef4444' : '#6b7280'};
`;

const AnnaWebinarSimple = () => {
  const [message, setMessage] = useState('Anna Webinar Demo - Simplified Version');
  const [backendStatus, setBackendStatus] = useState('checking');
  const [apiResponse, setApiResponse] = useState('');

  // Test backend connectivity on load
  useEffect(() => {
    testBackendHealth();
  }, []);

  const testBackendHealth = async () => {
    try {
      setBackendStatus('checking');
      const response = await fetch(`${process.env.REACT_APP_API_URL}/health`);
      if (response.ok) {
        const data = await response.json();
        setBackendStatus('connected');
        setApiResponse(`Backend healthy: ${data.status}`);
      } else {
        setBackendStatus('disconnected');
        setApiResponse(`Backend error: ${response.status}`);
      }
    } catch (error) {
      setBackendStatus('disconnected');
      setApiResponse(`Connection failed: ${error.message}`);
    }
  };

  const testBackendQuery = async () => {
    try {
      const response = await fetch(`${process.env.REACT_APP_API_URL}/query`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text: 'Hello from the frontend test!' }),
      });
      
      if (response.ok) {
        const data = await response.json();
        setApiResponse(`Query successful: ${data.answer || JSON.stringify(data)}`);
      } else {
        setApiResponse(`Query failed: ${response.status}`);
      }
    } catch (error) {
      setApiResponse(`Query error: ${error.message}`);
    }
  };

  return (
    <Container>
      <Content>
        <h1>{message}</h1>
        <p>Environment: {process.env.REACT_APP_ENV}</p>
        <p>Backend URL: {process.env.REACT_APP_API_URL}</p>
        
        <StatusIndicator status={backendStatus}>
          Backend Status: {backendStatus.toUpperCase()}
        </StatusIndicator>
        
        <div>
          <TestButton onClick={() => setMessage('Component is working!')}>
            Test React State
          </TestButton>
          
          <TestButton onClick={testBackendHealth}>
            Test Backend Health
          </TestButton>
          
          <TestButton onClick={testBackendQuery}>
            Test Backend Query
          </TestButton>
        </div>
        
        {apiResponse && (
          <div style={{ marginTop: '20px', padding: '10px', background: 'rgba(0,0,0,0.2)', borderRadius: '5px' }}>
            <strong>API Response:</strong>
            <pre style={{ whiteSpace: 'pre-wrap', fontSize: '12px' }}>{apiResponse}</pre>
          </div>
        )}
      </Content>
    </Container>
  );
};

export default AnnaWebinarSimple;

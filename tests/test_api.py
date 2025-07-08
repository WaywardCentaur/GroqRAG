"""
Integration tests for the FastAPI endpoints.
"""
import pytest
from fastapi.testclient import TestClient
import json
import base64
import numpy as np
from pathlib import Path
import os

def test_root_endpoint(test_client):
    """Test the root endpoint returns API documentation."""
    response = test_client.get("/")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]

def test_query_endpoint(test_client, mock_groq_response):
    """Test the query endpoint."""
    # Test with valid query
    response = test_client.post(
        "/query",
        json={"text": "What is this about?"}
    )
    assert response.status_code == 200
    
    # Test with invalid query
    response = test_client.post(
        "/query",
        json={"invalid": "data"}
    )
    assert response.status_code == 422

def test_document_upload(test_client, temp_dir):
    """Test document upload endpoint."""
    # Create a test document
    test_file = Path(temp_dir) / "test.txt"
    test_content = "This is a test document."
    test_file.write_text(test_content)
    
    with open(test_file, "rb") as f:
        response = test_client.post(
            "/documents",
            files={"file": ("test.txt", f, "text/plain")}
        )
    
    assert response.status_code == 200
    assert "Document processed successfully" in response.json()["message"]

@pytest.mark.asyncio
async def test_websocket_connection(websocket_client):
    """Test WebSocket connection and basic functionality."""
    # Send test audio data
    audio_data = {
        "type": "audio_data",
        "data": base64.b64encode(np.zeros(1600, dtype=np.int16).tobytes()).decode(),
        "format": "wav",
        "sample_rate": 16000
    }
    await websocket_client.send_json(audio_data)
    
    # Verify connection is maintained
    assert websocket_client.client_state.CONNECTED

@pytest.mark.asyncio
async def test_websocket_transcription(websocket_client):
    """Test real-time transcription via WebSocket."""
    # Generate test audio with a sine wave
    duration = 1.0
    sample_rate = 16000
    t = np.linspace(0, duration, int(sample_rate * duration))
    audio = (np.sin(2 * np.pi * 440 * t) * 32767).astype(np.int16)
    
    # Send audio data
    await websocket_client.send_json({
        "type": "audio_data",
        "data": base64.b64encode(audio.tobytes()).decode(),
        "format": "wav",
        "sample_rate": sample_rate
    })
    
    # Wait for and verify transcription response
    response = await websocket_client.receive_json()
    assert response["type"] in ["transcription", "error"]

def test_error_handling(test_client):
    """Test API error handling."""
    # Test invalid document upload
    response = test_client.post(
        "/documents",
        files={"file": ("test.txt", b"", "text/plain")}
    )
    assert response.status_code in [400, 422]
    
    # Test invalid query format
    response = test_client.post(
        "/query",
        json={"invalid": "format"}
    )
    assert response.status_code == 422
    
    # Test missing API key when required
    with pytest.MonkeyPatch.context() as mp:
        mp.setenv("REQUIRE_API_KEY", "true")
        response = test_client.post(
            "/query",
            json={"text": "test"},
            headers={"X-API-Key": "invalid"}
        )
        assert response.status_code == 401

def test_rate_limiting(test_client):
    """Test rate limiting functionality."""
    # Make multiple rapid requests
    responses = []
    for _ in range(50):  # Adjust based on rate limit
        response = test_client.post(
            "/query",
            json={"text": "test"}
        )
        responses.append(response.status_code)
    
    # Verify some requests were rate limited
    assert 429 in responses

@pytest.mark.asyncio
async def test_websocket_error_handling(websocket_client):
    """Test WebSocket error handling."""
    # Send invalid data
    await websocket_client.send_json({"type": "invalid"})
    
    # Verify error response
    response = await websocket_client.receive_json()
    assert response["type"] == "error"
    
    # Send malformed audio data
    await websocket_client.send_json({
        "type": "audio_data",
        "data": "invalid_base64"
    })
    
    # Verify error handling
    response = await websocket_client.receive_json()
    assert response["type"] == "error"

def test_concurrent_connections(test_client):
    """Test handling of concurrent WebSocket connections."""
    # Create multiple WebSocket connections
    connections = []
    for _ in range(5):
        conn = test_client.websocket_connect("/audio")
        connections.append(conn)
    
    # Verify all connections are accepted
    for conn in connections:
        assert conn.client_state.CONNECTED
        
    # Clean up connections
    for conn in connections:
        conn.close()

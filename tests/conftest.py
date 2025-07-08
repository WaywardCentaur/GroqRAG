"""
Test configuration and fixtures for the Audio RAG Agent.
"""
import pytest
import os
import asyncio
from pathlib import Path
from typing import Generator, AsyncGenerator
from fastapi.testclient import TestClient
import numpy as np
import tempfile
import json

# Add project root to Python path
import sys
sys.path.append(str(Path(__file__).parent.parent))

from src.main import app
from src.rag.pipeline import RAGPipeline
from src.audio.processor import AudioProcessor
from src.document_processor.processor import DocumentProcessor

@pytest.fixture
def test_client() -> Generator:
    """Create a test client for the FastAPI app."""
    with TestClient(app) as client:
        yield client

@pytest.fixture
def temp_dir() -> Generator:
    """Create a temporary directory for test files."""
    with tempfile.TemporaryDirectory() as tmp_dir:
        yield tmp_dir

@pytest.fixture
def mock_audio_data() -> bytes:
    """Generate mock audio data for testing."""
    # Create 1 second of 16-bit PCM audio at 16kHz
    duration = 1.0
    sample_rate = 16000
    t = np.linspace(0, duration, int(sample_rate * duration))
    audio = (np.sin(2 * np.pi * 440 * t) * 32767).astype(np.int16)
    return audio.tobytes()

@pytest.fixture
def rag_pipeline(temp_dir: str) -> RAGPipeline:
    """Create a RAG pipeline instance for testing."""
    return RAGPipeline(
        persist_directory=os.path.join(temp_dir, "chromadb"),
        chunk_size=100,  # Smaller chunks for testing
        chunk_overlap=20
    )

@pytest.fixture
def audio_processor() -> AudioProcessor:
    """Create an AudioProcessor instance for testing."""
    return AudioProcessor(
        sample_rate=16000,
        vad_frame_size=480,
        vad_mode=3
    )

@pytest.fixture
def sample_document() -> str:
    """Create a sample document for testing."""
    return """This is a test document.
    It contains multiple lines and sentences.
    This will be used for testing the RAG pipeline.
    The document has enough content to be split into chunks."""

@pytest.fixture
def sample_document_metadata() -> dict:
    """Create sample document metadata for testing."""
    return {
        "title": "Test Document",
        "author": "Test Author",
        "date": "2025-07-08"
    }

@pytest.fixture
def mock_groq_response() -> dict:
    """Create a mock response from the Groq LLM."""
    return {
        "answer": "This is a test response from the mock LLM.",
        "source_documents": [
            {"page_content": "Test content", "metadata": {"source": "test_doc"}}
        ]
    }

@pytest.fixture
async def websocket_client(test_client) -> AsyncGenerator:
    """Create a websocket test client."""
    async with test_client.websocket_connect("/audio") as websocket:
        yield websocket

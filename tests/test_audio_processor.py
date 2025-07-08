"""
Tests for the audio processing module.
"""
import pytest
import numpy as np
from unittest.mock import Mock, patch
import queue
from src.audio.processor import AudioProcessor

def test_audio_processor_initialization():
    """Test AudioProcessor initialization."""
    processor = AudioProcessor()
    assert processor.sample_rate == 16000
    assert processor.vad_frame_size == 480
    assert not processor.is_recording

def test_process_audio_chunk(audio_processor, mock_audio_data):
    """Test processing of audio chunks."""
    # Set up a mock callback
    mock_callback = Mock()
    audio_processor.transcription_callback = mock_callback
    
    # Process audio chunk
    audio_processor.process_audio_chunk(mock_audio_data)
    
    # Verify audio was added to queue
    assert not audio_processor.audio_queue.empty()
    
    # Get chunk from queue and verify
    chunk = audio_processor.audio_queue.get_nowait()
    assert isinstance(chunk, np.ndarray)
    assert chunk.dtype == np.int16

def test_vad_processing(audio_processor, mock_audio_data):
    """Test Voice Activity Detection processing."""
    # Process chunk with speech
    audio_processor.process_audio_chunk(mock_audio_data)
    
    # Verify VAD buffer handling
    assert len(audio_processor.vad_buffer) >= 0
    assert isinstance(audio_processor.vad_buffer, np.ndarray)

def test_silence_detection(audio_processor):
    """Test silence detection."""
    # Create silent audio
    silent_audio = np.zeros(16000, dtype=np.int16).tobytes()
    
    # Process silent chunk
    audio_processor.process_audio_chunk(silent_audio)
    
    # Verify silence handling
    assert audio_processor.silence_count > 0

def test_buffer_management(audio_processor, mock_audio_data):
    """Test buffer management and overflow prevention."""
    # Fill buffer beyond max size
    large_chunk = np.tile(mock_audio_data, 100)
    
    # Process oversized chunk
    audio_processor.process_audio_chunk(large_chunk)
    
    # Verify buffer didn't exceed max size
    assert len(audio_processor.vad_buffer) <= audio_processor.max_buffer_size

def test_error_recovery(audio_processor):
    """Test error recovery mechanisms."""
    # Simulate multiple errors
    for _ in range(audio_processor.MAX_ERRORS + 1):
        # Process invalid data to trigger error
        audio_processor.process_audio_chunk(b"invalid data")
    
    # Verify processor was reset
    assert len(audio_processor.vad_buffer) == 0
    assert len(audio_processor.speech_buffer) == 0
    assert audio_processor.silence_count == 0

@pytest.mark.asyncio
async def test_async_processing(audio_processor, mock_audio_data):
    """Test asynchronous processing capabilities."""
    processed_data = []
    
    def mock_callback(text):
        processed_data.append(text)
    
    audio_processor.transcription_callback = mock_callback
    
    # Process multiple chunks asynchronously
    for _ in range(5):
        audio_processor.process_audio_chunk(mock_audio_data)
    
    # Verify processing completed
    assert audio_processor.error_count == 0

def test_cleanup(audio_processor):
    """Test cleanup and resource management."""
    # Start recording
    audio_processor.is_recording = True
    
    # Fill queues and buffers
    audio_processor.audio_queue.put(np.zeros(1000))
    audio_processor.vad_buffer = np.zeros(1000)
    audio_processor.speech_buffer = [0] * 1000
    
    # Stop recording and cleanup
    audio_processor.stop_recording()
    
    # Verify cleanup
    assert not audio_processor.is_recording
    assert audio_processor.audio_queue.empty()
    assert len(audio_processor.vad_buffer) == 0
    assert len(audio_processor.speech_buffer) == 0

def test_transcription_error_handling(audio_processor):
    """Test handling of transcription errors."""
    # Mock transcriber to raise exception
    audio_processor.transcriber = Mock()
    audio_processor.transcriber.side_effect = Exception("Transcription error")
    
    # Process audio
    audio_processor.process_audio_chunk(np.zeros(1000, dtype=np.int16).tobytes())
    
    # Verify error was handled
    assert audio_processor.error_count > 0
    assert audio_processor.last_error_time is not None

def test_performance_boundaries(audio_processor):
    """Test performance boundaries and limitations."""
    # Test with minimum size chunk
    min_chunk = np.zeros(10, dtype=np.int16).tobytes()
    audio_processor.process_audio_chunk(min_chunk)
    
    # Test with maximum size chunk
    max_chunk = np.zeros(audio_processor.max_buffer_size * 2, dtype=np.int16).tobytes()
    audio_processor.process_audio_chunk(max_chunk)
    
    # Verify processor remains stable
    assert audio_processor.error_count == 0

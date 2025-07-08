"""
Audio processing module for real-time transcription using Groq Whisper.
"""
import os
import io
import wave
import tempfile
import asyncio
from typing import Dict, Optional, Any
import logging
from groq import Groq

logger = logging.getLogger(__name__)

class AudioProcessor:
    """
    Handles real-time audio processing and transcription using Groq Whisper.
    """
    
    def __init__(self):
        """Initialize the audio processor with Groq client."""
        self.groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        self.buffer = bytearray()
        self.min_chunk_size = 32000  # Minimum bytes for processing (~1 second at 16kHz)
        self.max_chunk_size = 320000  # Maximum bytes (~10 seconds at 16kHz)
        
    async def process_audio_chunk(self, audio_bytes: bytes, format_info: Dict[str, Any]) -> Optional[str]:
        """
        Process an audio chunk and return transcription.
        
        Args:
            audio_bytes: Raw audio data
            format_info: Audio format information (sample_rate, channels, etc.)
            
        Returns:
            Transcribed text or None if no speech detected
        """
        try:
            # Add new audio data to buffer
            self.buffer.extend(audio_bytes)
            
            # Check if we have enough data to process
            if len(self.buffer) < self.min_chunk_size:
                return None
            
            # Extract chunk to process (up to max_chunk_size)
            chunk_size = min(len(self.buffer), self.max_chunk_size)
            audio_chunk = bytes(self.buffer[:chunk_size])
            
            # Remove processed data from buffer
            self.buffer = self.buffer[chunk_size:]
            
            # Convert to WAV format for Whisper
            wav_data = self._convert_to_wav(
                audio_chunk, 
                format_info.get("sample_rate", 16000),
                format_info.get("channels", 1)
            )
            
            # Transcribe with Groq Whisper
            transcription = await self._transcribe_audio(wav_data)
            
            return transcription
            
        except Exception as e:
            logger.error(f"Error processing audio chunk: {e}")
            return None
    
    def _convert_to_wav(self, audio_data: bytes, sample_rate: int, channels: int) -> bytes:
        """
        Convert PCM audio data to WAV format.
        
        Args:
            audio_data: Raw PCM audio bytes
            sample_rate: Sample rate in Hz
            channels: Number of audio channels
            
        Returns:
            WAV formatted audio data
        """
        try:
            # Create WAV file in memory
            wav_buffer = io.BytesIO()
            
            with wave.open(wav_buffer, 'wb') as wav_file:
                wav_file.setnchannels(channels)
                wav_file.setsampwidth(2)  # 16-bit audio
                wav_file.setframerate(sample_rate)
                wav_file.writeframes(audio_data)
            
            wav_buffer.seek(0)
            return wav_buffer.read()
            
        except Exception as e:
            logger.error(f"Error converting to WAV: {e}")
            raise
    
    async def _transcribe_audio(self, wav_data: bytes) -> Optional[str]:
        """
        Transcribe audio using Groq Whisper API.
        
        Args:
            wav_data: WAV formatted audio data
            
        Returns:
            Transcribed text or None
        """
        try:
            # Create temporary file for Groq API
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
                temp_file.write(wav_data)
                temp_file_path = temp_file.name
            
            try:
                # Transcribe with Groq
                with open(temp_file_path, "rb") as audio_file:
                    transcription = self.groq_client.audio.transcriptions.create(
                        file=audio_file,
                        model="whisper-large-v3",
                        language="en",  # Specify language for better performance
                        response_format="text"
                    )
                
                # Clean up transcription text
                text = transcription.strip()
                
                # Filter out very short or meaningless transcriptions
                if len(text) < 3 or text.lower() in ["thank you.", "thanks.", "you"]:
                    return None
                
                return text
                
            finally:
                # Clean up temporary file
                os.unlink(temp_file_path)
                
        except Exception as e:
            logger.error(f"Error transcribing audio: {e}")
            return None
    
    async def cleanup(self):
        """Clean up any resources."""
        try:
            # Clear the buffer
            self.buffer.clear()
            logger.info("Audio processor cleaned up")
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")

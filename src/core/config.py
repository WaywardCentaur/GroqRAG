"""
Configuration module for the Real-Time Audio RAG Agent.
"""
import os
from typing import Optional

class Config:
    """Configuration settings for the application."""
    
    # API Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    WORKERS: int = int(os.getenv("WORKERS", "1"))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "info").lower()
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    
    # CORS Configuration
    CORS_ORIGINS: list = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # API Keys
    GROQ_API_KEY: Optional[str] = os.getenv("GROQ_API_KEY")
    
    # Database Configuration
    CHROMA_PERSIST_DIRECTORY: str = os.getenv("CHROMA_PERSIST_DIRECTORY", "data/chromadb")
    
    # Audio Configuration
    AUDIO_SAMPLE_RATE: int = int(os.getenv("AUDIO_SAMPLE_RATE", "16000"))
    AUDIO_CHANNELS: int = int(os.getenv("AUDIO_CHANNELS", "1"))
    AUDIO_CHUNK_SIZE: int = int(os.getenv("AUDIO_CHUNK_SIZE", "4096"))
    
    # Model Configuration
    EMBEDDING_MODEL: str = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
    WHISPER_MODEL: str = os.getenv("WHISPER_MODEL", "whisper-large-v3")
    LLM_MODEL: str = os.getenv("LLM_MODEL", "llama3-8b-8192")
    
    # RAG Configuration
    CHUNK_SIZE: int = int(os.getenv("CHUNK_SIZE", "1000"))
    CHUNK_OVERLAP: int = int(os.getenv("CHUNK_OVERLAP", "200"))
    TOP_K_RESULTS: int = int(os.getenv("TOP_K_RESULTS", "5"))
    
    @classmethod
    def validate(cls) -> bool:
        """Validate required configuration."""
        if not cls.GROQ_API_KEY:
            raise ValueError("GROQ_API_KEY environment variable is required")
        return True

# Global config instance
config = Config()

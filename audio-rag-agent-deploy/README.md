# Real-Time Audio RAG Agent with Groq

This project implements an AI agent that performs real-time audio transcription, processes documents, and uses a RAG (Retrieval Augmented Generation) pipeline with Groq for question answering.

## Features

- Real-time audio transcription
- Document processing (PDF, DOCX, TXT)
- RAG pipeline using Groq
- FastAPI-based REST API
- Vultr deployment configuration

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your Groq API key and other configurations
```

3. Run the application:
```bash
python src/main.py
```

## Project Structure

- `src/`: Source code
  - `audio/`: Audio processing modules
  - `document_processor/`: Document handling
  - `rag/`: RAG pipeline implementation
  - `api/`: FastAPI endpoints
- `tests/`: Unit tests
- `config/`: Configuration files
- `docs/`: Documentation

## License

MIT

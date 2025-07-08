"""
API routes for the Real-Time Audio RAG Agent.
"""
from typing import List, Optional
import os
import tempfile
from fastapi import APIRouter, File, UploadFile, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import json
import base64
import asyncio
import logging
from datetime import datetime

from core.audio_processor import AudioProcessor
from core.rag_pipeline import RAGPipeline

logger = logging.getLogger(__name__)
router = APIRouter()

# Initialize components lazily
_audio_processor = None
_rag_pipeline = None

def get_audio_processor():
    """Get or create audio processor instance."""
    global _audio_processor
    if _audio_processor is None:
        _audio_processor = AudioProcessor()
    return _audio_processor

def get_rag_pipeline():
    """Get or create RAG pipeline instance."""
    global _rag_pipeline
    if _rag_pipeline is None:
        _rag_pipeline = RAGPipeline()
    return _rag_pipeline

class QueryRequest(BaseModel):
    text: str

class QueryResponse(BaseModel):
    answer: str
    sources: List[str] = []

@router.post("/documents", response_model=dict)
async def upload_document(file: UploadFile = File(...)):
    """
    Upload a document to the RAG pipeline.
    
    Args:
        file: The document file to upload (PDF, TXT, DOCX)
        
    Returns:
        Success message with document ID
    """
    try:
        # Validate file type
        allowed_types = {
            "application/pdf": ".pdf",
            "text/plain": ".txt", 
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx"
        }
        
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400, 
                detail=f"Unsupported file type. Supported types: {list(allowed_types.values())}"
            )
        
        # Save uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=allowed_types[file.content_type]) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name
        
        try:
            # Process document with RAG pipeline
            rag_pipeline = get_rag_pipeline()
            document_id = await rag_pipeline.add_document(temp_file_path, file.filename)
            
            # Print success message to terminal
            print(f"✅ Document uploaded successfully:")
            print(f"   📄 Filename: {file.filename}")
            print(f"   🆔 Document ID: {document_id}")
            print(f"   📏 Size: {len(content):,} bytes")
            print(f"   📝 Content type: {file.content_type}")
            print("-" * 50)
            
            return {
                "message": f"Document '{file.filename}' uploaded successfully",
                "document_id": document_id,
                "filename": file.filename,
                "size": len(content)
            }
        finally:
            # Clean up temporary file
            os.unlink(temp_file_path)
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing document: {str(e)}")

@router.post("/query", response_model=str)
async def query_rag(request: QueryRequest):
    """
    Query the RAG pipeline with a text question.
    
    Args:
        request: The query request containing the question text
        
    Returns:
        The answer from the RAG pipeline
    """
    try:
        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Query text cannot be empty")
        
        # Query the RAG pipeline
        rag_pipeline = get_rag_pipeline()
        response = await rag_pipeline.query(request.text)
        
        # Print query information to terminal
        print(f"🔍 Query received:")
        print(f"   ❓ Question: {request.text}")
        print(f"   📚 Context chunks used: {response.get('context_chunks', 0)}")
        print(f"   📖 Sources found: {len(response.get('sources', []))}")
        
        # Show sources if available
        if response.get('sources'):
            print(f"   📋 Source documents:")
            for i, source in enumerate(response['sources'], 1):
                if 'filename' in source:
                    # Document source
                    filename = source.get('filename', 'Unknown')
                    chunk_idx = source.get('chunk_index', 0)
                    print(f"      {i}. {filename} (chunk {chunk_idx})")
                elif 'transcription_id' in source:
                    # Transcription source
                    source_type = source.get('source', 'audio')
                    timestamp = source.get('timestamp', 'Unknown time')
                    chunk_idx = source.get('chunk_index', 0)
                    print(f"      {i}. Transcription from {source_type} (chunk {chunk_idx}) - {timestamp}")
                else:
                    print(f"      {i}. Unknown source (chunk {source.get('chunk_index', 0)})")
        
        print(f"   💬 Answer: {response.get('answer', 'No answer found')[:100]}{'...' if len(response.get('answer', '')) > 100 else ''}")
        print("-" * 50)
        
        return response.get("answer", "No answer found")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing query: {str(e)}")

@router.websocket("/audio")
async def websocket_audio_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time audio processing.
    
    Accepts audio data and returns transcriptions.
    """
    await websocket.accept()
    print(f"🔌 WebSocket connection established for audio processing at {datetime.now().strftime('%H:%M:%S')}")
    
    try:
        while True:
            # Receive message from client
            message = await websocket.receive_text()
            
            try:
                data = json.loads(message)
                
                # Handle different message types
                if data.get("type") == "audio_data":
                    # Process audio data
                    audio_base64 = data.get("data", "")
                    format_info = {
                        "format": data.get("format", "pcm_s16le"),
                        "channels": data.get("channels", 1),
                        "sample_rate": data.get("sample_rate", 16000),
                        "samples": data.get("samples", 0)
                    }
                    
                    if audio_base64:
                        # Decode base64 audio data
                        audio_bytes = base64.b64decode(audio_base64)
                        
                        # Process audio through the audio processor
                        audio_processor = get_audio_processor()
                        transcription = await audio_processor.process_audio_chunk(
                            audio_bytes, format_info
                        )
                        
                        if transcription:
                            # Save transcription to RAG pipeline as context
                            rag_pipeline = get_rag_pipeline()
                            try:
                                transcription_id = await rag_pipeline.add_transcription(
                                    text=transcription,
                                    timestamp=datetime.now().isoformat(),
                                    source="audio_stream"
                                )
                            except Exception as e:
                                logger.error(f"Error saving transcription to RAG: {e}")
                            
                            # Print transcription to terminal
                            print(f"🎤 Audio transcription:")
                            print(f"   📝 Text: {transcription}")
                            print(f"   ⏰ Timestamp: {datetime.now().strftime('%H:%M:%S')}")
                            print("-" * 30)
                            
                            # Send transcription back to client
                            response = {
                                "type": "transcription",
                                "text": transcription,
                                "timestamp": datetime.now().isoformat()
                            }
                            await websocket.send_text(json.dumps(response))
                
                elif data.get("type") == "ping":
                    # Respond to ping with pong
                    await websocket.send_text(json.dumps({"type": "pong"}))
                
                elif data.get("type") == "stop":
                    # Handle stop signal
                    break
                    
            except json.JSONDecodeError:
                # Handle invalid JSON
                error_response = {
                    "type": "error",
                    "message": "Invalid JSON format"
                }
                await websocket.send_text(json.dumps(error_response))
                
            except Exception as e:
                # Handle processing errors
                error_response = {
                    "type": "error", 
                    "message": f"Error processing audio: {str(e)}"
                }
                await websocket.send_text(json.dumps(error_response))
                
    except WebSocketDisconnect:
        print(f"🔌 WebSocket client disconnected at {datetime.now().strftime('%H:%M:%S')}")
    except Exception as e:
        print(f"❌ WebSocket error: {e}")
    finally:
        # Clean up any resources
        audio_processor = get_audio_processor()
        await audio_processor.cleanup()
        print(f"🧹 Audio processor cleanup completed at {datetime.now().strftime('%H:%M:%S')}")

@router.get("/health")
async def health_check():
    """
    Health check endpoint.
    
    Returns:
        Service status information
    """
    try:
        # Check RAG pipeline and get counts
        rag_pipeline = get_rag_pipeline()
        documents = await rag_pipeline.list_documents()
        transcriptions = await rag_pipeline.list_transcriptions()
        
        return {
            "status": "healthy",
            "service": "Real-Time Audio RAG Agent",
            "timestamp": datetime.now().isoformat(),
            "components": {
                "audio_processor": "operational",
                "rag_pipeline": "operational",
                "transcription_system": "operational"
            },
            "data": {
                "documents_count": len(documents),
                "transcriptions_count": len(transcriptions)
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "service": "Real-Time Audio RAG Agent",
            "timestamp": datetime.now().isoformat(),
            "error": str(e)
        }

@router.delete("/transcriptions/{transcription_id}")
async def delete_transcription(transcription_id: str):
    """
    Delete a specific transcription from the RAG pipeline.
    
    Args:
        transcription_id: The ID of the transcription to delete
        
    Returns:
        Success message
    """
    try:
        rag_pipeline = get_rag_pipeline()
        success = await rag_pipeline.delete_transcription(transcription_id)
        
        if success:
            print(f"🗑️ Transcription deleted: {transcription_id}")
            return {"message": f"Transcription {transcription_id} deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="Transcription not found")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting transcription: {str(e)}")

@router.delete("/documents/{document_id}")
async def delete_document(document_id: str):
    """
    Delete a specific document from the RAG pipeline.
    
    Args:
        document_id: The ID of the document to delete
        
    Returns:
        Success message
    """
    try:
        rag_pipeline = get_rag_pipeline()
        success = await rag_pipeline.delete_document(document_id)
        
        if success:
            print(f"🗑️ Document deleted: {document_id}")
            return {"message": f"Document {document_id} deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="Document not found")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting document: {str(e)}")

@router.get("/transcriptions")
async def list_transcriptions():
    """
    List all audio transcriptions in the RAG pipeline.
    
    Returns:
        List of transcriptions with metadata
    """
    try:
        rag_pipeline = get_rag_pipeline()
        transcriptions = await rag_pipeline.list_transcriptions()
        return {"transcriptions": transcriptions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing transcriptions: {str(e)}")

@router.get("/documents")
async def list_documents():
    """
    List all uploaded documents in the RAG pipeline.
    
    Returns:
        List of documents with metadata
    """
    try:
        rag_pipeline = get_rag_pipeline()
        documents = await rag_pipeline.list_documents()
        return {"documents": documents}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing documents: {str(e)}")

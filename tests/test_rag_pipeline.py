"""
Tests for the RAG pipeline implementation.
"""
import pytest
from unittest.mock import Mock, patch
import json
import os
from datetime import datetime
from src.rag.pipeline import RAGPipeline

def test_rag_pipeline_initialization(temp_dir):
    """Test RAG pipeline initialization."""
    pipeline = RAGPipeline(persist_directory=temp_dir)
    assert pipeline.persist_directory == temp_dir
    assert pipeline.doc_metadata == {}

def test_add_documents(rag_pipeline, sample_document, sample_document_metadata):
    """Test adding documents to the RAG pipeline."""
    docs = [sample_document]
    metadata = [sample_document_metadata]
    
    rag_pipeline.add_documents(texts=docs, metadata=metadata)
    
    # Verify document was added
    doc_hash = rag_pipeline._compute_text_hash(sample_document)
    assert doc_hash in rag_pipeline.doc_metadata
    assert rag_pipeline.doc_metadata[doc_hash]["version"] == 1
    assert rag_pipeline.doc_metadata[doc_hash]["metadata"] == sample_document_metadata

def test_add_documents_versioning(rag_pipeline, sample_document):
    """Test document versioning when adding the same document multiple times."""
    # Add document first time
    rag_pipeline.add_documents([sample_document])
    doc_hash = rag_pipeline._compute_text_hash(sample_document)
    initial_version = rag_pipeline.doc_metadata[doc_hash]["version"]
    
    # Add same document again
    rag_pipeline.add_documents([sample_document])
    assert rag_pipeline.doc_metadata[doc_hash]["version"] == initial_version + 1

def test_query_with_caching(rag_pipeline, mock_groq_response):
    """Test query functionality with caching."""
    question = "What is this document about?"
    
    # Mock the chain response
    rag_pipeline.chain = Mock()
    rag_pipeline.chain.return_value = mock_groq_response
    
    # First query
    response1 = rag_pipeline.query(question)
    assert response1 == mock_groq_response["answer"]
    rag_pipeline.chain.assert_called_once()
    
    # Second query (should use cache)
    response2 = rag_pipeline.query(question)
    assert response2 == mock_groq_response["answer"]
    # Chain should not be called again
    rag_pipeline.chain.assert_called_once()

def test_query_with_filter(rag_pipeline, mock_groq_response):
    """Test query with filter criteria."""
    question = "What is this document about?"
    filter_criteria = {"metadata_field": "test_value"}
    
    # Mock the chain response
    rag_pipeline.chain = Mock()
    rag_pipeline.chain.return_value = mock_groq_response
    
    response = rag_pipeline.query(question, filter_criteria=filter_criteria)
    assert response == mock_groq_response["answer"]
    
    # Verify filter was applied
    assert rag_pipeline.chain.retriever.search_kwargs["filter"] == filter_criteria

def test_add_to_context(rag_pipeline):
    """Test adding text to conversation context."""
    test_text = "This is a test input"
    source_type = "test"
    timestamp = datetime.now().isoformat()
    
    # Mock the memory
    rag_pipeline.memory = Mock()
    
    rag_pipeline.add_to_context(test_text, source_type, timestamp)
    
    # Verify memory was updated
    rag_pipeline.memory.save_context.assert_called_once_with(
        {"input": test_text},
        {"output": None, "source": source_type, "timestamp": timestamp}
    )

def test_error_handling(rag_pipeline):
    """Test error handling in RAG pipeline."""
    # Test document addition error
    with pytest.raises(Exception):
        rag_pipeline.add_documents([None])
    
    # Test query error
    rag_pipeline.chain = Mock()
    rag_pipeline.chain.side_effect = Exception("Test error")
    with pytest.raises(Exception):
        rag_pipeline.query("test question")

def test_metadata_persistence(temp_dir):
    """Test that document metadata is properly persisted."""
    pipeline = RAGPipeline(persist_directory=temp_dir)
    doc = "Test document"
    pipeline.add_documents([doc])
    
    # Create new pipeline instance
    new_pipeline = RAGPipeline(persist_directory=temp_dir)
    doc_hash = new_pipeline._compute_text_hash(doc)
    
    # Verify metadata was loaded
    assert doc_hash in new_pipeline.doc_metadata
    assert new_pipeline.doc_metadata[doc_hash]["version"] == 1

@pytest.mark.asyncio
async def test_memory_management(rag_pipeline):
    """Test memory management and cleanup."""
    # Add multiple documents
    docs = ["Doc 1", "Doc 2", "Doc 3"]
    initial_memory = rag_pipeline.memory.buffer_size
    
    for doc in docs:
        rag_pipeline.add_documents([doc])
        
    # Verify memory is cleaned up
    assert rag_pipeline.memory.buffer_size <= initial_memory * 2

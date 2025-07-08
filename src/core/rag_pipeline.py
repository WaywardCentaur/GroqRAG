"""
RAG (Retrieval-Augmented Generation) pipeline using ChromaDB and Groq.
"""
import os
import uuid
from typing import List, Dict, Any, Optional
import logging
from pathlib import Path
import hashlib
from datetime import datetime

# Document processing
import PyPDF2
from docx import Document as DocxDocument
import chromadb
from chromadb.config import Settings

# LangChain components
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document
from langchain_community.embeddings import HuggingFaceEmbeddings

# Groq for LLM
from groq import Groq

logger = logging.getLogger(__name__)

class RAGPipeline:
    """
    RAG pipeline for document processing and question answering.
    """
    
    def __init__(self):
        """Initialize the RAG pipeline with ChromaDB and Groq."""
        # Initialize Groq client
        self.groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        
        # Initialize ChromaDB
        self.chroma_persist_directory = os.path.join(os.getcwd(), "data", "chromadb")
        os.makedirs(self.chroma_persist_directory, exist_ok=True)
        
        self.chroma_client = chromadb.PersistentClient(
            path=self.chroma_persist_directory,
            settings=Settings(anonymized_telemetry=False)
        )
        
        # Get or create collection
        self.collection_name = "documents"
        try:
            self.collection = self.chroma_client.get_collection(self.collection_name)
        except Exception:
            # Collection doesn't exist, create it
            self.collection = self.chroma_client.create_collection(
                name=self.collection_name,
                metadata={"description": "Document collection for RAG pipeline"}
            )
        
        # Initialize embeddings model
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'}
        )
        
        # Initialize text splitter
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            separators=["\n\n", "\n", " ", ""]
        )
        
        # Document metadata storage
        self.documents_metadata = {}
        
    async def add_document(self, file_path: str, filename: str) -> str:
        """
        Add a document to the RAG pipeline.
        
        Args:
            file_path: Path to the document file
            filename: Original filename
            
        Returns:
            Document ID
        """
        try:
            # Extract text from document
            text_content = self._extract_text_from_file(file_path, filename)
            
            if not text_content.strip():
                raise ValueError("No text content extracted from document")
            
            # Generate document ID
            doc_id = str(uuid.uuid4())
            
            # Create document hash for deduplication
            content_hash = hashlib.md5(text_content.encode()).hexdigest()
            
            # Check if document already exists
            existing_docs = self.collection.get(
                where={"content_hash": content_hash}
            )
            
            if existing_docs['ids']:
                logger.info(f"Document with same content already exists: {existing_docs['ids'][0]}")
                return existing_docs['ids'][0]
            
            # Split text into chunks
            documents = self.text_splitter.create_documents([text_content])
            
            # Process each chunk
            chunk_ids = []
            chunk_texts = []
            chunk_embeddings = []
            chunk_metadatas = []
            
            for i, doc in enumerate(documents):
                chunk_id = f"{doc_id}_chunk_{i}"
                chunk_ids.append(chunk_id)
                chunk_texts.append(doc.page_content)
                
                # Generate embedding
                embedding = self.embeddings.embed_query(doc.page_content)
                chunk_embeddings.append(embedding)
                
                # Create metadata
                metadata = {
                    "document_id": doc_id,
                    "filename": filename,
                    "chunk_index": i,
                    "content_hash": content_hash,
                    "source": file_path
                }
                chunk_metadatas.append(metadata)
            
            # Add to ChromaDB
            self.collection.add(
                ids=chunk_ids,
                documents=chunk_texts,
                embeddings=chunk_embeddings,
                metadatas=chunk_metadatas
            )
            
            # Store document metadata
            self.documents_metadata[doc_id] = {
                "filename": filename,
                "content_hash": content_hash,
                "chunk_count": len(documents),
                "source": file_path
            }
            
            logger.info(f"Added document '{filename}' with {len(documents)} chunks")
            return doc_id
            
        except Exception as e:
            logger.error(f"Error adding document: {e}")
            raise
    
    def _extract_text_from_file(self, file_path: str, filename: str) -> str:
        """
        Extract text content from various file formats.
        
        Args:
            file_path: Path to the file
            filename: Original filename
            
        Returns:
            Extracted text content
        """
        try:
            file_extension = Path(filename).suffix.lower()
            
            if file_extension == ".pdf":
                return self._extract_pdf_text(file_path)
            elif file_extension == ".docx":
                return self._extract_docx_text(file_path)
            elif file_extension == ".txt":
                return self._extract_txt_text(file_path)
            else:
                raise ValueError(f"Unsupported file format: {file_extension}")
                
        except Exception as e:
            logger.error(f"Error extracting text from {filename}: {e}")
            raise
    
    def _extract_pdf_text(self, file_path: str) -> str:
        """Extract text from PDF file."""
        text = ""
        try:
            with open(file_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                for page in pdf_reader.pages:
                    text += page.extract_text() + "\n"
        except Exception as e:
            logger.error(f"Error extracting PDF text: {e}")
            raise
        return text
    
    def _extract_docx_text(self, file_path: str) -> str:
        """Extract text from DOCX file."""
        try:
            doc = DocxDocument(file_path)
            text = "\n".join([paragraph.text for paragraph in doc.paragraphs])
            return text
        except Exception as e:
            logger.error(f"Error extracting DOCX text: {e}")
            raise
    
    def _extract_txt_text(self, file_path: str) -> str:
        """Extract text from TXT file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                return file.read()
        except Exception as e:
            logger.error(f"Error extracting TXT text: {e}")
            raise
    
    async def query(self, question: str, top_k: int = 5) -> Dict[str, Any]:
        """
        Query the RAG pipeline with a question.
        
        Args:
            question: The question to ask
            top_k: Number of top chunks to retrieve
            
        Returns:
            Dictionary containing answer and sources
        """
        try:
            # Generate query embedding
            query_embedding = self.embeddings.embed_query(question)
            
            # Search for relevant chunks
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k
            )
            
            if not results['documents'][0]:
                return {
                    "answer": "I couldn't find any relevant information to answer your question.",
                    "sources": []
                }
            
            # Prepare context from retrieved chunks
            context_chunks = results['documents'][0]
            # Filter out None values and ensure all chunks are strings
            context_chunks = [str(chunk) for chunk in context_chunks if chunk is not None and str(chunk).strip()]
            
            if not context_chunks:
                return {
                    "answer": "I couldn't find any relevant information to answer your question.",
                    "sources": []
                }
            
            context = "\n\n".join(context_chunks)
            
            # Generate answer using Groq
            answer = await self._generate_answer(question, context)
            
            # Extract source information
            sources = []
            for metadata in results['metadatas'][0]:
                if metadata.get('source_type') == 'transcription':
                    # Transcription source
                    source_info = {
                        "transcription_id": metadata.get("transcription_id", "Unknown"),
                        "source": metadata.get("source", "audio"),
                        "timestamp": metadata.get("timestamp", "Unknown"),
                        "chunk_index": metadata.get("chunk_index", 0)
                    }
                else:
                    # Document source
                    source_info = {
                        "filename": metadata.get("filename", "Unknown"),
                        "chunk_index": metadata.get("chunk_index", 0)
                    }
                
                if source_info not in sources:
                    sources.append(source_info)
            
            return {
                "answer": answer,
                "sources": sources,
                "context_chunks": len(context_chunks)
            }
            
        except Exception as e:
            logger.error(f"Error querying RAG pipeline: {e}")
            raise
    
    async def _generate_answer(self, question: str, context: str) -> str:
        """
        Generate an answer using Groq LLM.
        
        Args:
            question: The user's question
            context: Retrieved context from documents
            
        Returns:
            Generated answer
        """
        try:
            # Ensure context is a valid string
            if not context or not isinstance(context, str):
                context = "No specific context available."
            
            # Create prompt
            prompt = f"""Based on the following context, please answer the question. If the context doesn't contain enough information to answer the question, please say so.

Context:
{context}

Question: {question}

Answer:"""
            
            # Generate response with Groq
            response = self.groq_client.chat.completions.create(
                model="llama3-8b-8192",
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a helpful assistant that answers questions based on provided context. Be concise and accurate."
                    },
                    {
                        "role": "user", 
                        "content": prompt
                    }
                ],
                temperature=0.1,
                max_tokens=1000
            )
            
            # Check if response is valid
            if not response.choices or not response.choices[0].message.content:
                return "I encountered an issue generating the answer. Please try again."
                
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            logger.error(f"Error generating answer: {e}")
            return "I encountered an error while generating the answer. Please try again."
    
    async def list_documents(self) -> List[Dict[str, Any]]:
        """
        List all documents in the pipeline.
        
        Returns:
            List of document metadata
        """
        try:
            # Get all items from collection
            all_items = self.collection.get()
            
            unique_docs = {}
            for metadata in all_items['metadatas']:
                # Only include actual documents (not transcriptions)
                if metadata.get('source_type') == 'transcription':
                    continue
                    
                doc_id = metadata.get('document_id')
                if doc_id and doc_id not in unique_docs:
                    unique_docs[doc_id] = {
                        "document_id": doc_id,
                        "filename": metadata.get('filename', 'Unknown'),
                        "chunk_count": 0
                    }
                if doc_id:
                    unique_docs[doc_id]["chunk_count"] += 1
            
            return list(unique_docs.values())
            
        except Exception as e:
            logger.error(f"Error listing documents: {e}")
            return []
    
    async def add_transcription(self, text: str, timestamp: str = None, source: str = "audio") -> str:
        """
        Add an audio transcription to the RAG pipeline as context.
        
        Args:
            text: The transcribed text
            timestamp: When the transcription was created
            source: Source of the transcription (default: "audio")
            
        Returns:
            Transcription ID
        """
        try:
            if not text.strip():
                raise ValueError("Transcription text cannot be empty")
            
            # Generate transcription ID
            transcription_id = str(uuid.uuid4())
            
            # Create document hash for deduplication
            content_hash = hashlib.md5(text.encode()).hexdigest()
            
            # Check if transcription already exists
            existing_transcriptions = self.collection.get(
                where={
                    "$and": [
                        {"content_hash": content_hash},
                        {"source_type": "transcription"}
                    ]
                }
            )
            
            if existing_transcriptions['ids']:
                logger.info(f"Transcription with same content already exists: {existing_transcriptions['ids'][0]}")
                return existing_transcriptions['ids'][0]
            
            # Split text into chunks if it's long
            documents = self.text_splitter.create_documents([text])
            
            # Process each chunk
            chunk_ids = []
            chunk_texts = []
            chunk_embeddings = []
            chunk_metadatas = []
            
            for i, doc in enumerate(documents):
                chunk_id = f"{transcription_id}_chunk_{i}"
                chunk_ids.append(chunk_id)
                chunk_texts.append(doc.page_content)
                
                # Generate embedding
                embedding = self.embeddings.embed_query(doc.page_content)
                chunk_embeddings.append(embedding)
                
                # Create metadata for transcription
                metadata = {
                    "transcription_id": transcription_id,
                    "source_type": "transcription",
                    "source": source,
                    "chunk_index": i,
                    "content_hash": content_hash,
                    "timestamp": timestamp or datetime.now().isoformat()
                }
                chunk_metadatas.append(metadata)
            
            # Add to ChromaDB
            self.collection.add(
                ids=chunk_ids,
                documents=chunk_texts,
                embeddings=chunk_embeddings,
                metadatas=chunk_metadatas
            )
            
            # Store transcription metadata
            self.documents_metadata[transcription_id] = {
                "source_type": "transcription",
                "source": source,
                "content_hash": content_hash,
                "chunk_count": len(documents),
                "timestamp": timestamp or datetime.now().isoformat()
            }
            
            logger.info(f"Added transcription with {len(documents)} chunks from {source}")
            return transcription_id
            
        except Exception as e:
            logger.error(f"Error adding transcription: {e}")
            raise

    async def delete_transcription(self, transcription_id: str) -> bool:
        """
        Delete a transcription from the RAG pipeline.
        
        Args:
            transcription_id: ID of the transcription to delete
            
        Returns:
            True if deletion was successful, False if not found
        """
        try:
            # Get all chunks for this transcription
            transcription_chunks = self.collection.get(
                where={"transcription_id": {"$eq": transcription_id}}
            )
            
            if not transcription_chunks['ids']:
                logger.warning(f"Transcription {transcription_id} not found")
                return False
            
            # Delete chunks from collection
            self.collection.delete(ids=transcription_chunks['ids'])
            
            # Remove from metadata storage
            if transcription_id in self.documents_metadata:
                del self.documents_metadata[transcription_id]
            
            logger.info(f"Deleted transcription {transcription_id} with {len(transcription_chunks['ids'])} chunks")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting transcription {transcription_id}: {e}")
            raise

    async def delete_document(self, document_id: str) -> bool:
        """
        Delete a document from the RAG pipeline.
        
        Args:
            document_id: ID of the document to delete
            
        Returns:
            True if deletion was successful, False if not found
        """
        try:
            # Get all chunks for this document
            document_chunks = self.collection.get(
                where={"document_id": {"$eq": document_id}}
            )
            
            if not document_chunks['ids']:
                logger.warning(f"Document {document_id} not found")
                return False
            
            # Delete chunks from collection
            self.collection.delete(ids=document_chunks['ids'])
            
            # Remove from metadata storage
            if document_id in self.documents_metadata:
                del self.documents_metadata[document_id]
            
            logger.info(f"Deleted document {document_id} with {len(document_chunks['ids'])} chunks")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting document {document_id}: {e}")
            raise

    async def list_transcriptions(self) -> List[Dict[str, Any]]:
        """
        List all transcriptions in the pipeline.
        
        Returns:
            List of transcription metadata
        """
        try:
            # Get transcriptions from collection
            transcriptions = self.collection.get(
                where={"source_type": {"$eq": "transcription"}}
            )
            
            unique_transcriptions = {}
            for metadata in transcriptions['metadatas']:
                transcription_id = metadata['transcription_id']
                if transcription_id not in unique_transcriptions:
                    unique_transcriptions[transcription_id] = {
                        "transcription_id": transcription_id,
                        "source": metadata['source'],
                        "timestamp": metadata['timestamp'],
                        "chunk_count": 0
                    }
                unique_transcriptions[transcription_id]["chunk_count"] += 1
            
            return list(unique_transcriptions.values())
            
        except Exception as e:
            logger.error(f"Error listing transcriptions: {e}")
            return []

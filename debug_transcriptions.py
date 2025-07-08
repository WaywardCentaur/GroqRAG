"""
Debug script to check transcription storage.
"""
import asyncio
import sys
import os

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.rag_pipeline import RAGPipeline

async def debug_transcriptions():
    """Debug transcription storage and retrieval."""
    print("🔍 Debugging Transcription Storage")
    print("=" * 50)
    
    rag = RAGPipeline()
    
    # Get all data from collection
    all_data = rag.collection.get()
    
    print(f"📊 Total items in collection: {len(all_data['ids'])}")
    
    if all_data['ids']:
        print("\n📝 Collection contents:")
        for i, (doc_id, metadata, document) in enumerate(zip(all_data['ids'], all_data['metadatas'], all_data['documents'])):
            print(f"\n{i+1}. ID: {doc_id}")
            print(f"   Metadata: {metadata}")
            print(f"   Document: {document[:100]}{'...' if len(document) > 100 else ''}")
    
    # Test embedding search
    print(f"\n🔍 Testing embedding search for 'test transcription'...")
    query_embedding = rag.embeddings.embed_query("test transcription")
    results = rag.collection.query(
        query_embeddings=[query_embedding],
        n_results=5
    )
    
    print(f"   Search results: {len(results['documents'][0])} documents found")
    if results['documents'][0]:
        for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
            print(f"   {i+1}. {doc[:100]}{'...' if len(doc) > 100 else ''}")
            print(f"      Metadata: {metadata}")

if __name__ == "__main__":
    asyncio.run(debug_transcriptions())

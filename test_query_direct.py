"""
Test the query method directly.
"""
import asyncio
import sys
import os

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.rag_pipeline import RAGPipeline

async def test_query():
    """Test query method directly."""
    print("🔍 Testing Query Method")
    print("=" * 50)
    
    rag = RAGPipeline()
    
    # Test query
    result = await rag.query("test transcription")
    
    print(f"📝 Query: 'test transcription'")
    print(f"💬 Answer: {result['answer']}")
    print(f"📊 Sources: {result['sources']}")
    print(f"📖 Context chunks: {result['context_chunks']}")

if __name__ == "__main__":
    asyncio.run(test_query())

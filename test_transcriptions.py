"""
Test script to verify transcription functionality.
"""
import asyncio
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

async def test_transcription_system():
    """Test the transcription system functionality."""
    print("🧪 Testing Transcription System")
    print("=" * 50)
    
    # Test 1: Health check
    print("1. Testing health check...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        health_data = response.json()
        print(f"   ✅ Health Status: {health_data['status']}")
        print(f"   📊 Documents: {health_data.get('data', {}).get('documents_count', 0)}")
        print(f"   🎤 Transcriptions: {health_data.get('data', {}).get('transcriptions_count', 0)}")
    except Exception as e:
        print(f"   ❌ Health check failed: {e}")
        return
    
    # Test 2: Add a test transcription directly via RAG pipeline
    print("\n2. Testing transcription saving...")
    try:
        # Import and test the RAG pipeline directly
        import sys
        import os
        sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))
        
        from core.rag_pipeline import RAGPipeline
        
        rag = RAGPipeline()
        transcription_text = "This is a test transcription from the audio processing system. It contains sample speech that was converted to text."
        
        transcription_id = await rag.add_transcription(
            text=transcription_text,
            timestamp=datetime.now().isoformat(),
            source="test_audio"
        )
        
        print(f"   ✅ Transcription saved with ID: {transcription_id}")
        
        # Test listing transcriptions
        transcriptions = await rag.list_transcriptions()
        print(f"   📝 Total transcriptions: {len(transcriptions)}")
        
        if transcriptions:
            latest = transcriptions[-1]
            print(f"   📊 Latest transcription:")
            print(f"      - Source: {latest['source']}")
            print(f"      - Timestamp: {latest['timestamp']}")
            print(f"      - Chunks: {latest['chunk_count']}")
        
    except Exception as e:
        print(f"   ❌ Transcription test failed: {e}")
        return
    
    # Test 3: Query with transcription context
    print("\n3. Testing query with transcription context...")
    try:
        query_data = {"text": "What did the test audio say?"}
        response = requests.post(
            f"{BASE_URL}/query",
            headers={"Content-Type": "application/json"},
            json=query_data
        )
        
        if response.status_code == 200:
            answer = response.text.strip('"')
            print(f"   ✅ Query successful!")
            print(f"   💬 Answer: {answer[:100]}{'...' if len(answer) > 100 else ''}")
        else:
            print(f"   ❌ Query failed with status: {response.status_code}")
            
    except Exception as e:
        print(f"   ❌ Query test failed: {e}")
    
    # Test 4: API endpoint for listing transcriptions
    print("\n4. Testing transcription API endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/transcriptions")
        if response.status_code == 200:
            data = response.json()
            transcriptions = data.get('transcriptions', [])
            print(f"   ✅ API endpoint working!")
            print(f"   📝 Found {len(transcriptions)} transcriptions via API")
        else:
            print(f"   ❌ API endpoint failed with status: {response.status_code}")
    except Exception as e:
        print(f"   ❌ API test failed: {e}")
    
    print("\n" + "=" * 50)
    print("🎉 Transcription system test completed!")

if __name__ == "__main__":
    asyncio.run(test_transcription_system())

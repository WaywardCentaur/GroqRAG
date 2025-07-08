"""
Test script for table and delete functionality.
"""
import asyncio
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

async def test_table_functionality():
    """Test the table and delete functionality."""
    print("🧪 Testing Table and Delete Functionality")
    print("=" * 60)
    
    # First, let's add some test data
    print("1. Adding test data...")
    
    try:
        # Import and test the RAG pipeline directly
        import sys
        import os
        sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))
        
        from core.rag_pipeline import RAGPipeline
        
        rag = RAGPipeline()
        
        # Add test transcriptions
        transcription_ids = []
        for i in range(3):
            transcription_text = f"This is test transcription number {i+1}. It contains sample audio content that was processed and converted to text for testing purposes."
            
            transcription_id = await rag.add_transcription(
                text=transcription_text,
                timestamp=datetime.now().isoformat(),
                source=f"test_audio_{i+1}"
            )
            transcription_ids.append(transcription_id)
            print(f"   ✅ Added test transcription {i+1}: {transcription_id[:8]}...")
        
        print(f"   📝 Added {len(transcription_ids)} test transcriptions")
        
    except Exception as e:
        print(f"   ❌ Error adding test data: {e}")
        return
    
    # Test 2: List transcriptions via API
    print("\n2. Testing transcriptions table...")
    try:
        response = requests.get(f"{BASE_URL}/transcriptions")
        if response.status_code == 200:
            data = response.json()
            transcriptions = data.get('transcriptions', [])
            print(f"   ✅ Found {len(transcriptions)} transcriptions")
            for i, t in enumerate(transcriptions[:3]):
                print(f"      {i+1}. {t['transcription_id'][:8]}... ({t['source']})")
        else:
            print(f"   ❌ Failed to get transcriptions: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Error testing transcriptions: {e}")
    
    # Test 3: List documents via API
    print("\n3. Testing documents table...")
    try:
        response = requests.get(f"{BASE_URL}/documents")
        if response.status_code == 200:
            data = response.json()
            documents = data.get('documents', [])
            print(f"   ✅ Found {len(documents)} documents")
            if documents:
                for i, d in enumerate(documents[:3]):
                    print(f"      {i+1}. {d['document_id'][:8]}... ({d['filename']})")
            else:
                print("   📄 No documents found (this is expected if none were uploaded)")
        else:
            print(f"   ❌ Failed to get documents: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Error testing documents: {e}")
    
    # Test 4: Delete a transcription
    if transcription_ids:
        print("\n4. Testing transcription deletion...")
        try:
            test_id = transcription_ids[0]
            response = requests.delete(f"{BASE_URL}/transcriptions/{test_id}")
            
            if response.status_code == 200:
                print(f"   ✅ Successfully deleted transcription {test_id[:8]}...")
                
                # Verify deletion
                response = requests.get(f"{BASE_URL}/transcriptions")
                if response.status_code == 200:
                    data = response.json()
                    remaining = len(data.get('transcriptions', []))
                    print(f"   ✅ Remaining transcriptions: {remaining}")
                    
            else:
                error_text = response.text
                print(f"   ❌ Failed to delete: {response.status_code} - {error_text}")
                
        except Exception as e:
            print(f"   ❌ Error testing deletion: {e}")
    
    # Test 5: Test health check with counts
    print("\n5. Testing health check...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            health_data = response.json()
            print(f"   ✅ Health Status: {health_data['status']}")
            data_counts = health_data.get('data', {})
            print(f"   📊 Documents: {data_counts.get('documents_count', 0)}")
            print(f"   🎤 Transcriptions: {data_counts.get('transcriptions_count', 0)}")
        else:
            print(f"   ❌ Health check failed: {response.status_code}")
    except Exception as e:
        print(f"   ❌ Error with health check: {e}")
    
    print("\n" + "=" * 60)
    print("🎉 Table and delete functionality test completed!")
    print("📝 You can now test the web interface at http://localhost:8000")
    print("   • Click 'Refresh Documents' to see the documents table")
    print("   • Click 'Refresh Transcriptions' to see the transcriptions table")
    print("   • Use the Delete buttons to remove items")

if __name__ == "__main__":
    asyncio.run(test_table_functionality())

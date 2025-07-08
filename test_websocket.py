#!/usr/bin/env python3

import asyncio
import websockets
import json
import sys

async def test_websocket():
    uri = "ws://149.28.123.26:8000/audio"
    print(f"Attempting to connect to: {uri}")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ WebSocket connection successful!")
            
            # Send a ping message
            ping_msg = json.dumps({"type": "ping"})
            await websocket.send(ping_msg)
            print("📤 Sent ping message")
            
            # Wait for response
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5)
                print(f"📥 Received: {response}")
                
                # Try to parse the response
                try:
                    data = json.loads(response)
                    if data.get("type") == "pong":
                        print("✅ WebSocket communication successful!")
                        return True
                    else:
                        print(f"⚠️  Unexpected response type: {data.get('type')}")
                        return False
                except json.JSONDecodeError:
                    print(f"⚠️  Received non-JSON response: {response}")
                    return False
                    
            except asyncio.TimeoutError:
                print("⚠️  No response received within timeout")
                return False
                
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ WebSocket connection failed with status code: {e.status_code}")
        print(f"   Headers: {e.headers}")
        return False
    except websockets.exceptions.ConnectionClosed as e:
        print(f"❌ WebSocket connection closed: {e}")
        return False
    except Exception as e:
        print(f"❌ WebSocket connection failed: {type(e).__name__}: {e}")
        return False

if __name__ == "__main__":
    try:
        result = asyncio.run(test_websocket())
        sys.exit(0 if result else 1)
    except KeyboardInterrupt:
        print("\n⚠️  Test interrupted by user")
        sys.exit(1)

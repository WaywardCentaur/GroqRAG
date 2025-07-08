#!/bin/bash

# =============================================================================
# WebSocket and Audio Testing Script for Audio RAG Agent
# =============================================================================
# Tests WebSocket connectivity and simulates audio data transmission
# Usage: ./websocket-test.sh [SERVER_IP]
# =============================================================================

set -e

# Configuration
DEFAULT_SERVER_IP="149.28.123.26"
SERVER_IP="${1:-$DEFAULT_SERVER_IP}"
WS_URL="ws://${SERVER_IP}:8000/audio"
HTTP_URL="http://${SERVER_IP}:8000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_failure() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test WebSocket using curl (HTTP upgrade)
test_websocket_with_curl() {
    print_info "Testing WebSocket connection with curl..."
    
    # First check if the endpoint responds to HTTP requests
    local response=$(curl -s -w "%{http_code}" "${HTTP_URL}/audio" -o /dev/null 2>/dev/null || echo "000")
    
    if [ "$response" = "405" ]; then
        print_success "WebSocket endpoint correctly rejects HTTP GET (405 Method Not Allowed)"
        return 0
    elif [ "$response" = "426" ]; then
        print_success "WebSocket endpoint requires upgrade (426 Upgrade Required)"
        return 0
    else
        print_warning "WebSocket endpoint returned HTTP $response"
        return 1
    fi
}

# Test WebSocket using netcat
test_websocket_with_netcat() {
    print_info "Testing WebSocket connection with netcat..."
    
    if ! command -v nc > /dev/null 2>&1; then
        print_warning "netcat not available, skipping"
        return 1
    fi
    
    # Create a simple WebSocket handshake
    local handshake="GET /audio HTTP/1.1\r
Host: ${SERVER_IP}:8000\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r
Sec-WebSocket-Version: 13\r
\r
"
    
    # Send handshake and check response
    local response=$(echo -e "$handshake" | timeout 5 nc "$SERVER_IP" 8000 2>/dev/null | head -1)
    
    if echo "$response" | grep -q "101"; then
        print_success "WebSocket handshake successful (101 Switching Protocols)"
        return 0
    elif echo "$response" | grep -q "400\|404\|405"; then
        local code=$(echo "$response" | grep -o '[0-9]\{3\}')
        print_failure "WebSocket handshake failed with HTTP $code"
        return 1
    else
        print_warning "WebSocket handshake response unclear: $response"
        return 1
    fi
}

# Test WebSocket using Python
test_websocket_with_python() {
    print_info "Testing WebSocket connection with Python..."
    
    if ! command -v python3 > /dev/null 2>&1; then
        print_warning "Python3 not available, skipping"
        return 1
    fi
    
    # Create a simple Python WebSocket test
    python3 -c "
import asyncio
import json
import sys
try:
    import websockets
except ImportError:
    print('websockets module not available')
    sys.exit(1)

async def test_websocket():
    try:
        print('Connecting to WebSocket...')
        async with websockets.connect('$WS_URL', timeout=10) as websocket:
            print('✅ WebSocket connection successful')
            
            # Send a ping message
            ping_msg = json.dumps({'type': 'ping'})
            await websocket.send(ping_msg)
            print('📤 Sent ping message')
            
            # Wait for response
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5)
                print(f'📥 Received: {response}')
                print('✅ WebSocket communication successful')
            except asyncio.TimeoutError:
                print('⚠️  No response received (timeout)')
            
    except websockets.exceptions.ConnectionClosed as e:
        print(f'❌ WebSocket connection closed: {e}')
        sys.exit(1)
    except Exception as e:
        print(f'❌ WebSocket connection failed: {e}')
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(test_websocket())
" 2>/dev/null
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        print_success "Python WebSocket test passed"
        return 0
    else
        print_failure "Python WebSocket test failed"
        return 1
    fi
}

# Test WebSocket endpoint availability
test_websocket_endpoint() {
    print_info "Checking WebSocket endpoint in API documentation..."
    
    local openapi=$(curl -s "${HTTP_URL}/openapi.json" 2>/dev/null)
    
    if echo "$openapi" | jq -e '.paths["/audio"]' > /dev/null 2>&1; then
        print_success "WebSocket endpoint '/audio' found in API documentation"
        return 0
    else
        print_warning "WebSocket endpoint '/audio' not found in API documentation"
        return 1
    fi
}

# Simulate audio data transmission
test_audio_data_simulation() {
    print_info "Testing audio data simulation..."
    
    # This would require a more complex setup, so we'll just check the endpoint
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"type": "test", "message": "audio test"}' \
        "${HTTP_URL}/audio" 2>/dev/null || echo "connection_error")
    
    if [ "$response" = "connection_error" ]; then
        print_warning "HTTP POST to audio endpoint failed (expected for WebSocket-only endpoint)"
    else
        print_info "Audio endpoint response: $response"
    fi
}

# Check server logs for WebSocket-related errors
check_server_logs() {
    print_info "Checking recent server logs for WebSocket errors..."
    
    # This requires SSH access, so we'll skip if not available
    if ssh -o ConnectTimeout=5 -o BatchMode=yes root@${SERVER_IP} "echo test" > /dev/null 2>&1; then
        print_info "Checking Docker container logs..."
        ssh root@${SERVER_IP} "cd /opt/audio-rag-agent && docker-compose logs --tail=20 app" 2>/dev/null | \
            grep -E "(websocket|WebSocket|audio|error)" | tail -10 || print_info "No recent WebSocket-related logs found"
    else
        print_warning "Cannot check server logs (SSH access required)"
    fi
}

# Main test execution
main() {
    print_header "WebSocket and Audio Testing for Audio RAG Agent"
    echo -e "${BLUE}Target Server: ${WS_URL}${NC}"
    echo -e "${BLUE}Test Started: $(date)${NC}"
    echo ""
    
    local tests_passed=0
    local total_tests=0
    
    # Test 1: WebSocket endpoint documentation
    echo "Test 1: WebSocket Endpoint Documentation"
    total_tests=$((total_tests + 1))
    if test_websocket_endpoint; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 2: WebSocket with curl
    echo "Test 2: WebSocket HTTP Response"
    total_tests=$((total_tests + 1))
    if test_websocket_with_curl; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 3: WebSocket with netcat
    echo "Test 3: WebSocket Handshake"
    total_tests=$((total_tests + 1))
    if test_websocket_with_netcat; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 4: WebSocket with Python
    echo "Test 4: WebSocket Communication"
    total_tests=$((total_tests + 1))
    if test_websocket_with_python; then
        tests_passed=$((tests_passed + 1))
    fi
    echo ""
    
    # Test 5: Audio data simulation
    echo "Test 5: Audio Data Endpoint"
    total_tests=$((total_tests + 1))
    test_audio_data_simulation
    echo ""
    
    # Check server logs
    echo "Additional: Server Logs Check"
    check_server_logs
    echo ""
    
    # Summary
    print_header "WebSocket Test Summary"
    echo -e "${BLUE}Tests Passed: ${tests_passed}/${total_tests}${NC}"
    
    if [ $tests_passed -eq $total_tests ]; then
        print_success "All WebSocket tests passed! The endpoint appears to be working correctly."
        echo ""
        print_info "To test the full audio functionality:"
        print_info "1. Open http://${SERVER_IP}:8000 in your browser"
        print_info "2. Click 'Start Tab Audio Processing'"
        print_info "3. Select a browser tab with audio and enable 'Share audio'"
        print_info "4. Monitor the console for WebSocket connection messages"
        return 0
    else
        print_failure "Some WebSocket tests failed. Check the issues above."
        echo ""
        print_info "Troubleshooting steps:"
        print_info "1. Verify the server is running: curl ${HTTP_URL}/health"
        print_info "2. Check Docker logs: docker-compose logs app"
        print_info "3. Ensure firewall allows WebSocket connections on port 8000"
        print_info "4. Test with browser developer tools Network tab"
        return 1
    fi
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [SERVER_IP]"
    echo ""
    echo "Test WebSocket connectivity and audio functionality of the Audio RAG Agent."
    echo ""
    echo "Arguments:"
    echo "  SERVER_IP    IP address of the deployed server (default: $DEFAULT_SERVER_IP)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Test default server"
    echo "  $0 192.168.1.100     # Test custom server"
    echo ""
    echo "This script tests:"
    echo "  - WebSocket endpoint availability"
    echo "  - WebSocket handshake process"
    echo "  - Basic WebSocket communication"
    echo "  - Audio endpoint functionality"
    echo "  - Server logs for errors"
    echo ""
    echo "Dependencies:"
    echo "  - curl (required)"
    echo "  - nc/netcat (recommended)"
    echo "  - python3 with websockets module (recommended)"
    echo ""
    echo "To install Python websockets:"
    echo "  pip3 install websockets"
    exit 0
fi

# Run main function
main "$@"

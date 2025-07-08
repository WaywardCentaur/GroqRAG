#!/bin/bash

# =============================================================================
# Audio RAG Agent - Deployment Testing Script
# =============================================================================
# This script tests all functionality of the deployed Audio RAG Agent
# Usage: ./test-deployment.sh [SERVER_IP]
# =============================================================================

set -e  # Exit on any error

# Configuration
DEFAULT_SERVER_IP="149.28.123.26"
SERVER_IP="${1:-$DEFAULT_SERVER_IP}"
BASE_URL="http://${SERVER_IP}:8000"
TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================================${NC}"
}

print_test() {
    echo -e "${YELLOW}🧪 Testing: $1${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_success() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

print_failure() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Test if server is reachable
test_server_reachable() {
    print_test "Server Reachability"
    if curl -s --connect-timeout 5 "${BASE_URL}" > /dev/null 2>&1; then
        print_success "Server is reachable at ${BASE_URL}"
    else
        print_failure "Server is not reachable at ${BASE_URL}"
        echo "Please check if the server is running and the IP address is correct."
        exit 1
    fi
}

# Test health endpoint
test_health_endpoint() {
    print_test "Health Endpoint"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/health")
    local status=$(echo $response | jq -r '.status' 2>/dev/null || echo "error")
    
    if [ "$status" = "healthy" ]; then
        print_success "Health endpoint returns healthy status"
        print_info "Health details: $(echo $response | jq -c '.components' 2>/dev/null || echo 'N/A')"
    else
        print_failure "Health endpoint not healthy. Response: $response"
    fi
}

# Test API documentation
test_api_docs() {
    print_test "API Documentation"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/docs")
    
    if echo "$response" | grep -q "swagger-ui" && echo "$response" | grep -q "Real-Time Audio RAG Agent"; then
        print_success "API documentation is accessible"
    else
        print_failure "API documentation not accessible or malformed"
    fi
}

# Test OpenAPI schema
test_openapi_schema() {
    print_test "OpenAPI Schema"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/openapi.json")
    local title=$(echo $response | jq -r '.info.title' 2>/dev/null || echo "error")
    
    if [ "$title" = "Real-Time Audio RAG Agent" ]; then
        print_success "OpenAPI schema is valid"
        local version=$(echo $response | jq -r '.info.version' 2>/dev/null || echo "unknown")
        print_info "API Version: $version"
    else
        print_failure "OpenAPI schema invalid or not accessible"
    fi
}

# Test web interface
test_web_interface() {
    print_test "Web Interface"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/")
    
    if echo "$response" | grep -q "Audio RAG Tester" && echo "$response" | grep -q "<!DOCTYPE html>"; then
        print_success "Web interface is accessible"
    else
        print_failure "Web interface not accessible or malformed"
    fi
}

# Test documents endpoint
test_documents_endpoint() {
    print_test "Documents Endpoint"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/documents")
    
    # Check if it's a valid JSON response with documents array
    if echo "$response" | jq empty 2>/dev/null && echo "$response" | jq -e 'has("documents")' > /dev/null 2>&1; then
        local count=$(echo "$response" | jq '.documents | length')
        print_success "Documents endpoint accessible (${count} documents)"
    else
        print_failure "Documents endpoint error: $response"
    fi
}

# Test transcriptions endpoint
test_transcriptions_endpoint() {
    print_test "Transcriptions Endpoint"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/transcriptions")
    
    # Check if it's a valid JSON response with transcriptions array
    if echo "$response" | jq empty 2>/dev/null && echo "$response" | jq -e 'has("transcriptions")' > /dev/null 2>&1; then
        local count=$(echo "$response" | jq '.transcriptions | length')
        print_success "Transcriptions endpoint accessible (${count} transcriptions)"
    else
        print_failure "Transcriptions endpoint error: $response"
    fi
}

# Test query endpoint with sample query
test_query_endpoint() {
    print_test "Query Endpoint"
    local test_query="{\"text\": \"What is artificial intelligence?\"}"
    local response=$(curl -s --max-time $TIMEOUT -X POST \
        -H "Content-Type: application/json" \
        -d "$test_query" \
        "${BASE_URL}/query")
    
    # Check if response is a JSON error or a plain string response
    if echo "$response" | jq empty 2>/dev/null; then
        # It's valid JSON - check if it's an error response
        local has_detail=$(echo "$response" | jq -e 'has("detail")' 2>/dev/null || echo "false")
        if [ "$has_detail" = "true" ]; then
            print_failure "Query endpoint error: $response"
        else
            # It's valid JSON but not an error - this might be unexpected
            print_failure "Query endpoint returned unexpected JSON format: $response"
        fi
    else
        # It's a plain string response (expected for successful queries)
        # Remove quotes if the response is a JSON string
        local clean_response=$(echo "$response" | sed 's/^"//;s/"$//')
        if [ ${#clean_response} -gt 10 ]; then
            print_success "Query endpoint working (RAG pipeline operational)"
            local response_text=$(echo "$clean_response" | head -c 100)
            print_info "Sample response: ${response_text}..."
        else
            print_failure "Query endpoint returned empty or very short response: $response"
        fi
    fi
}

# Test WebSocket connection (basic connectivity)
test_websocket_connection() {
    print_test "WebSocket Audio Endpoint Connectivity"
    
    # Check if websocat is available for WebSocket testing
    if command -v websocat > /dev/null 2>&1; then
        # Test WebSocket connection (just connectivity, not full audio stream)
        if timeout 5 websocat "ws://${SERVER_IP}:8000/audio" <<< '{"type":"test"}' > /dev/null 2>&1; then
            print_success "WebSocket audio endpoint is accessible"
        else
            print_failure "WebSocket audio endpoint not accessible (this might be expected without audio data)"
        fi
    else
        print_info "WebSocket test skipped (websocat not installed)"
        print_info "To install websocat: cargo install websocat or use package manager"
    fi
}

# Test file upload (create a test file)
test_file_upload() {
    print_test "File Upload Functionality"
    
    # Create a temporary test file
    local test_file="/tmp/test_document_$(date +%s).txt"
    echo "This is a test document for the Audio RAG Agent deployment test.
It contains sample content to verify that document upload functionality works correctly.
The document processing pipeline should be able to extract and index this content." > "$test_file"
    
    # Upload the file
    local response=$(curl -s --max-time $TIMEOUT -X POST \
        -F "file=@${test_file}" \
        "${BASE_URL}/documents")
    
    # Clean up test file
    rm -f "$test_file"
    
    # Check response
    if echo "$response" | jq empty 2>/dev/null; then
        local has_message=$(echo "$response" | jq -e 'has("message")' 2>/dev/null || echo "false")
        local has_doc_id=$(echo "$response" | jq -e 'has("document_id")' 2>/dev/null || echo "false")
        if [ "$has_message" = "true" ] && [ "$has_doc_id" = "true" ]; then
            local doc_id=$(echo "$response" | jq -r '.document_id')
            print_success "File upload working (Document ID: ${doc_id})"
            
            # Optionally clean up the uploaded test document
            print_info "Cleaning up test document..."
            curl -s --max-time $TIMEOUT -X DELETE "${BASE_URL}/documents/${doc_id}" > /dev/null 2>&1
        else
            print_failure "File upload returned unexpected format: $response"
        fi
    else
        print_failure "File upload error: $response"
    fi
}

# Test response times
test_response_times() {
    print_test "Response Time Performance"
    
    local health_time=$(curl -o /dev/null -s -w '%{time_total}' "${BASE_URL}/health")
    local docs_time=$(curl -o /dev/null -s -w '%{time_total}' "${BASE_URL}/documents")
    
    print_info "Health endpoint response time: ${health_time}s"
    print_info "Documents endpoint response time: ${docs_time}s"
    
    # Check if response times are reasonable (under 5 seconds)
    if (( $(echo "$health_time < 5.0" | bc -l) )) && (( $(echo "$docs_time < 5.0" | bc -l) )); then
        print_success "Response times are acceptable"
    else
        print_failure "Response times are too slow (health: ${health_time}s, docs: ${docs_time}s)"
    fi
}

# Test error handling
test_error_handling() {
    print_test "Error Handling"
    
    # Test 404 endpoint
    local response=$(curl -s -w '%{http_code}' "${BASE_URL}/nonexistent" | tail -c 3)
    if [ "$response" = "404" ]; then
        print_success "404 error handling works correctly"
    else
        print_failure "404 error handling not working (got HTTP $response)"
    fi
    
    # Test invalid query
    local invalid_response=$(curl -s --max-time $TIMEOUT -X POST \
        -H "Content-Type: application/json" \
        -d '{"invalid": "json structure"}' \
        "${BASE_URL}/query")
    
    if echo "$invalid_response" | grep -q "error\|detail" || echo "$invalid_response" | jq -e 'has("detail")' > /dev/null 2>&1; then
        print_success "Invalid query error handling works"
    else
        print_failure "Invalid query error handling not working"
    fi
}

# =============================================================================
# Main Test Execution
# =============================================================================

main() {
    print_header "Audio RAG Agent Deployment Testing"
    echo -e "${BLUE}Target Server: ${BASE_URL}${NC}"
    echo -e "${BLUE}Test Started: $(date)${NC}"
    echo ""
    
    # Check dependencies
    if ! command -v curl > /dev/null 2>&1; then
        echo -e "${RED}Error: curl is required but not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: jq not found. Some JSON parsing tests may be limited${NC}"
    fi
    
    if ! command -v bc > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: bc not found. Response time comparisons may be limited${NC}"
    fi
    
    echo ""
    
    # Run all tests
    test_server_reachable
    echo ""
    
    test_health_endpoint
    echo ""
    
    test_api_docs
    echo ""
    
    test_openapi_schema
    echo ""
    
    test_web_interface
    echo ""
    
    test_documents_endpoint
    echo ""
    
    test_transcriptions_endpoint
    echo ""
    
    test_query_endpoint
    echo ""
    
    test_websocket_connection
    echo ""
    
    test_file_upload
    echo ""
    
    test_response_times
    echo ""
    
    test_error_handling
    echo ""
    
    # Print summary
    print_header "Test Summary"
    echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${BLUE}Success Rate: ${success_rate}%${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Deployment is successful and fully functional.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Please review the failures above.${NC}"
        exit 1
    fi
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [SERVER_IP]"
    echo ""
    echo "Test the Audio RAG Agent deployment."
    echo ""
    echo "Arguments:"
    echo "  SERVER_IP    IP address of the deployed server (default: $DEFAULT_SERVER_IP)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Test default server"
    echo "  $0 192.168.1.100     # Test custom server"
    echo ""
    echo "Dependencies:"
    echo "  - curl (required)"
    echo "  - jq (recommended for JSON parsing)"
    echo "  - bc (recommended for math operations)"
    echo "  - websocat (optional for WebSocket testing)"
    exit 0
fi

# Run main function
main "$@"

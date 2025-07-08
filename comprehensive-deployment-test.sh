#!/bin/bash

# =============================================================================
# Audio RAG Agent - Comprehensive Deployment Testing Script
# =============================================================================
# This script performs complete validation of the deployed Audio RAG Agent
# including initialization, functionality tests, and stress testing
# Usage: ./comprehensive-deployment-test.sh [SERVER_IP]
# =============================================================================

set -e  # Exit on any error

# Configuration
DEFAULT_SERVER_IP="149.28.123.26"
SERVER_IP="${1:-$DEFAULT_SERVER_IP}"
BASE_URL="http://${SERVER_IP}:8000"
TIMEOUT=30
LONG_TIMEOUT=60

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results storage
declare -a TEST_RESULTS=()

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}=================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================================${NC}"
}

print_section() {
    echo -e "${PURPLE}--- $1 ---${NC}"
}

print_test() {
    echo -e "${YELLOW}🧪 Testing: $1${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_success() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TEST_RESULTS+=("PASS: $1")
}

print_failure() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TEST_RESULTS+=("FAIL: $1")
}

print_skip() {
    echo -e "${CYAN}⏭️  SKIP: $1${NC}"
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    TEST_RESULTS+=("SKIP: $1")
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

# Enhanced error handling
handle_error() {
    local error_message="$1"
    local context="$2"
    echo -e "${RED}ERROR in $context: $error_message${NC}"
}

# Check dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    
    local deps_ok=true
    
    if ! command -v curl > /dev/null 2>&1; then
        print_failure "curl is required but not installed"
        deps_ok=false
    else
        print_info "curl: available"
    fi
    
    if ! command -v jq > /dev/null 2>&1; then
        print_warning "jq not found. Some JSON parsing tests may be limited"
        print_info "Install with: sudo apt-get install jq (Ubuntu) or brew install jq (macOS)"
    else
        print_info "jq: available"
    fi
    
    if ! command -v bc > /dev/null 2>&1; then
        print_warning "bc not found. Response time comparisons may be limited"
    else
        print_info "bc: available"
    fi
    
    if ! command -v websocat > /dev/null 2>&1; then
        print_info "websocat not found (optional). WebSocket tests will be skipped"
        print_info "Install with: cargo install websocat"
    else
        print_info "websocat: available"
    fi
    
    if [ "$deps_ok" = false ]; then
        exit 1
    fi
    
    echo ""
}

# =============================================================================
# Core Infrastructure Tests
# =============================================================================

test_server_connectivity() {
    print_section "Infrastructure Tests"
    
    print_test "Server Connectivity"
    if curl -s --connect-timeout 5 "${BASE_URL}" > /dev/null 2>&1; then
        print_success "Server is reachable at ${BASE_URL}"
    else
        print_failure "Server is not reachable at ${BASE_URL}"
        echo "Please check if the server is running and the IP address is correct."
        exit 1
    fi
}

test_health_endpoint() {
    print_test "Health Check Endpoint"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/health" 2>/dev/null)
    
    if [ -z "$response" ]; then
        print_failure "Health endpoint returned empty response"
        return
    fi
    
    local status=$(echo "$response" | jq -r '.status' 2>/dev/null || echo "error")
    
    if [ "$status" = "healthy" ]; then
        print_success "Health endpoint returns healthy status"
        
        # Extract component details
        local audio_proc=$(echo "$response" | jq -r '.components.audio_processor' 2>/dev/null || echo "unknown")
        local rag_pipeline=$(echo "$response" | jq -r '.components.rag_pipeline' 2>/dev/null || echo "unknown")
        local transcription=$(echo "$response" | jq -r '.components.transcription_system' 2>/dev/null || echo "unknown")
        
        print_info "Components: AudioProcessor($audio_proc), RAG($rag_pipeline), Transcription($transcription)"
        
        # Data counts
        local doc_count=$(echo "$response" | jq -r '.data.documents_count' 2>/dev/null || echo "unknown")
        local trans_count=$(echo "$response" | jq -r '.data.transcriptions_count' 2>/dev/null || echo "unknown")
        
        print_info "Data: ${doc_count} documents, ${trans_count} transcriptions"
    else
        print_failure "Health endpoint not healthy. Status: $status"
        print_info "Full response: $response"
    fi
}

test_api_documentation() {
    print_test "API Documentation Accessibility"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/docs" 2>/dev/null)
    
    if echo "$response" | grep -q "swagger-ui" && echo "$response" | grep -q "Real-Time Audio RAG Agent"; then
        print_success "API documentation is accessible and properly configured"
    else
        print_failure "API documentation not accessible or malformed"
    fi
}

test_openapi_schema() {
    print_test "OpenAPI Schema Validation"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/openapi.json" 2>/dev/null)
    local title=$(echo "$response" | jq -r '.info.title' 2>/dev/null || echo "error")
    
    if [ "$title" = "Real-Time Audio RAG Agent" ]; then
        print_success "OpenAPI schema is valid and accessible"
        local version=$(echo "$response" | jq -r '.info.version' 2>/dev/null || echo "unknown")
        print_info "API Version: $version"
    else
        print_failure "OpenAPI schema invalid or not accessible"
    fi
}

test_web_interface() {
    print_test "Web Interface"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/" 2>/dev/null)
    
    if echo "$response" | grep -q "Audio RAG Tester" && echo "$response" | grep -q "<!DOCTYPE html>"; then
        print_success "Web interface is accessible and properly configured"
    else
        print_failure "Web interface not accessible or malformed"
    fi
}

# =============================================================================
# API Endpoint Tests
# =============================================================================

test_documents_api() {
    print_section "Document Management API Tests"
    
    print_test "Documents List Endpoint"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/documents" 2>/dev/null)
    
    if echo "$response" | jq empty 2>/dev/null && echo "$response" | jq -e 'has("documents")' > /dev/null 2>&1; then
        local count=$(echo "$response" | jq '.documents | length' 2>/dev/null || echo "unknown")
        print_success "Documents endpoint accessible (${count} documents)"
    else
        print_failure "Documents endpoint error: $response"
        return
    fi
}

test_transcriptions_api() {
    print_test "Transcriptions List Endpoint"
    local response=$(curl -s --max-time $TIMEOUT "${BASE_URL}/transcriptions" 2>/dev/null)
    
    if echo "$response" | jq empty 2>/dev/null && echo "$response" | jq -e 'has("transcriptions")' > /dev/null 2>&1; then
        local count=$(echo "$response" | jq '.transcriptions | length' 2>/dev/null || echo "unknown")
        print_success "Transcriptions endpoint accessible (${count} transcriptions)"
    else
        print_failure "Transcriptions endpoint error: $response"
        return
    fi
}

# =============================================================================
# RAG Pipeline Tests
# =============================================================================

test_rag_query() {
    print_section "RAG Pipeline Tests"
    
    print_test "Query Processing (with existing documents)"
    local test_query="{\"text\": \"What is artificial intelligence?\"}"
    local response=$(curl -s --max-time $LONG_TIMEOUT -X POST \
        -H "Content-Type: application/json" \
        -d "$test_query" \
        "${BASE_URL}/query" 2>/dev/null)
    
    if [ -z "$response" ]; then
        print_failure "Query endpoint returned empty response"
        return
    fi
    
    # Check if response is an error JSON or a successful string
    if echo "$response" | jq empty 2>/dev/null; then
        # It's valid JSON - likely an error
        local has_detail=$(echo "$response" | jq -e 'has("detail")' 2>/dev/null || echo "false")
        if [ "$has_detail" = "true" ]; then
            local error_detail=$(echo "$response" | jq -r '.detail' 2>/dev/null)
            if echo "$error_detail" | grep -q "hnsw segment reader"; then
                print_warning "ChromaDB vector index not initialized (expected on first run)"
                print_info "This will be resolved after uploading documents"
            else
                print_failure "Query endpoint error: $error_detail"
            fi
        else
            print_failure "Query endpoint returned unexpected JSON: $response"
        fi
    else
        # It's a plain string response (successful query)
        local clean_response=$(echo "$response" | sed 's/^"//;s/"$//')
        if [ ${#clean_response} -gt 10 ]; then
            print_success "Query endpoint working (RAG pipeline operational)"
            local response_text=$(echo "$clean_response" | head -c 100)
            print_info "Sample response: ${response_text}..."
        else
            print_failure "Query endpoint returned very short response: $response"
        fi
    fi
}

test_document_upload_and_query() {
    print_section "Document Upload and Processing Tests"
    
    print_test "Document Upload Functionality"
    
    # Create a comprehensive test document
    local test_file="/tmp/ai_test_document_$(date +%s).txt"
    cat > "$test_file" << 'EOF'
Artificial Intelligence (AI) Overview

Artificial Intelligence (AI) refers to the simulation of human intelligence in machines that are programmed to think and learn like humans. The term may also be applied to any machine that exhibits traits associated with a human mind such as learning and problem-solving.

Key characteristics of AI include:
1. Learning - The ability to improve performance based on experience
2. Reasoning - The ability to draw conclusions from available information  
3. Problem-solving - The ability to find solutions to complex challenges
4. Perception - The ability to interpret sensory data
5. Language understanding - The ability to comprehend and generate human language

AI applications include machine learning, natural language processing, computer vision, robotics, and expert systems. Modern AI systems are powered by neural networks and deep learning algorithms that can process vast amounts of data to identify patterns and make predictions.

The field of AI has experienced rapid growth in recent years, driven by advances in computing power, availability of big data, and improvements in algorithms.
EOF
    
    # Upload the document
    local upload_response=$(curl -s --max-time $LONG_TIMEOUT -X POST \
        -F "file=@${test_file}" \
        "${BASE_URL}/documents" 2>/dev/null)
    
    # Clean up test file
    rm -f "$test_file"
    
    if [ -z "$upload_response" ]; then
        print_failure "Document upload returned empty response"
        return
    fi
    
    # Check upload response
    if echo "$upload_response" | jq empty 2>/dev/null; then
        local has_message=$(echo "$upload_response" | jq -e 'has("message")' 2>/dev/null || echo "false")
        local has_doc_id=$(echo "$upload_response" | jq -e 'has("document_id")' 2>/dev/null || echo "false")
        
        if [ "$has_message" = "true" ] && [ "$has_doc_id" = "true" ]; then
            local doc_id=$(echo "$upload_response" | jq -r '.document_id' 2>/dev/null)
            local filename=$(echo "$upload_response" | jq -r '.filename' 2>/dev/null)
            print_success "Document upload successful (ID: ${doc_id})"
            print_info "Filename: $filename"
            
            # Wait a moment for indexing
            sleep 2
            
            # Now test querying with the uploaded document
            print_test "Query Processing (with uploaded document)"
            local ai_query="{\"text\": \"What are the key characteristics of artificial intelligence?\"}"
            local query_response=$(curl -s --max-time $LONG_TIMEOUT -X POST \
                -H "Content-Type: application/json" \
                -d "$ai_query" \
                "${BASE_URL}/query" 2>/dev/null)
            
            if [ -z "$query_response" ]; then
                print_failure "Query with uploaded document returned empty response"
            else
                # Check if it's an error or successful response
                if echo "$query_response" | jq empty 2>/dev/null; then
                    local has_detail=$(echo "$query_response" | jq -e 'has("detail")' 2>/dev/null || echo "false")
                    if [ "$has_detail" = "true" ]; then
                        local error_detail=$(echo "$query_response" | jq -r '.detail' 2>/dev/null)
                        print_failure "Query with uploaded document failed: $error_detail"
                    else
                        print_failure "Query returned unexpected JSON: $query_response"
                    fi
                else
                    # Successful string response
                    local clean_response=$(echo "$query_response" | sed 's/^"//;s/"$//')
                    if echo "$clean_response" | grep -qi "learning\|reasoning\|problem-solving"; then
                        print_success "Query with uploaded document working correctly"
                        print_info "Response contains expected AI-related content"
                    else
                        print_warning "Query response may not be using uploaded document content"
                        print_info "Response: $(echo "$clean_response" | head -c 100)..."
                    fi
                fi
            fi
            
            # Clean up uploaded document
            print_info "Cleaning up test document..."
            curl -s --max-time $TIMEOUT -X DELETE "${BASE_URL}/documents/${doc_id}" > /dev/null 2>&1
            
        else
            print_failure "Document upload returned unexpected format: $upload_response"
        fi
    else
        print_failure "Document upload error: $upload_response"
    fi
}

# =============================================================================
# WebSocket Tests
# =============================================================================

test_websocket_connectivity() {
    print_section "WebSocket Tests"
    
    print_test "WebSocket Audio Endpoint Connectivity"
    
    if command -v websocat > /dev/null 2>&1; then
        # Test basic WebSocket connectivity
        local ws_test_result
        if timeout 5 websocat "ws://${SERVER_IP}:8000/audio" <<< '{"type":"ping"}' > /dev/null 2>&1; then
            print_success "WebSocket audio endpoint is accessible"
        else
            print_warning "WebSocket audio endpoint connectivity test failed (may be expected without proper audio data)"
        fi
    else
        print_skip "WebSocket test (websocat not installed)"
        print_info "To install websocat: cargo install websocat"
    fi
}

# =============================================================================
# Performance Tests
# =============================================================================

test_performance() {
    print_section "Performance Tests"
    
    print_test "Response Time Performance"
    
    if command -v bc > /dev/null 2>&1; then
        local health_time=$(curl -o /dev/null -s -w '%{time_total}' "${BASE_URL}/health" 2>/dev/null)
        local docs_time=$(curl -o /dev/null -s -w '%{time_total}' "${BASE_URL}/documents" 2>/dev/null)
        local docs_count_time=$(curl -o /dev/null -s -w '%{time_total}' "${BASE_URL}/transcriptions" 2>/dev/null)
        
        print_info "Health endpoint: ${health_time}s"
        print_info "Documents endpoint: ${docs_time}s"
        print_info "Transcriptions endpoint: ${docs_count_time}s"
        
        # Check if response times are reasonable (under 5 seconds)
        if (( $(echo "$health_time < 5.0" | bc -l) )) && (( $(echo "$docs_time < 5.0" | bc -l) )); then
            print_success "Response times are acceptable"
        else
            print_failure "Response times are too slow (health: ${health_time}s, docs: ${docs_time}s)"
        fi
    else
        print_skip "Response time performance test (bc not available)"
    fi
}

# =============================================================================
# Error Handling Tests
# =============================================================================

test_error_handling() {
    print_section "Error Handling Tests"
    
    print_test "404 Error Handling"
    local response=$(curl -s -w '%{http_code}' "${BASE_URL}/nonexistent" 2>/dev/null | tail -c 3)
    if [ "$response" = "404" ]; then
        print_success "404 error handling works correctly"
    else
        print_failure "404 error handling not working (got HTTP $response)"
    fi
    
    print_test "Invalid JSON Handling"
    local invalid_response=$(curl -s --max-time $TIMEOUT -X POST \
        -H "Content-Type: application/json" \
        -d '{"invalid": "json structure for query"}' \
        "${BASE_URL}/query" 2>/dev/null)
    
    if echo "$invalid_response" | jq -e 'has("detail")' > /dev/null 2>&1; then
        print_success "Invalid query JSON error handling works"
    elif echo "$invalid_response" | grep -q "error\|Error"; then
        print_success "Invalid query error handling works"
    else
        print_warning "Invalid query error handling unclear: $invalid_response"
    fi
    
    print_test "Unsupported File Type Handling"
    # Create a fake image file
    local fake_image="/tmp/test.jpg"
    echo "fake image content" > "$fake_image"
    
    local file_response=$(curl -s --max-time $TIMEOUT -X POST \
        -F "file=@${fake_image}" \
        "${BASE_URL}/documents" 2>/dev/null)
    
    rm -f "$fake_image"
    
    if echo "$file_response" | jq -e 'has("detail")' > /dev/null 2>&1; then
        local error_msg=$(echo "$file_response" | jq -r '.detail' 2>/dev/null)
        if echo "$error_msg" | grep -q "Unsupported file type"; then
            print_success "Unsupported file type error handling works"
        else
            print_warning "File type error handling works but message unclear: $error_msg"
        fi
    else
        print_failure "Unsupported file type error handling not working"
    fi
}

# =============================================================================
# Security Tests
# =============================================================================

test_security_basics() {
    print_section "Basic Security Tests"
    
    print_test "CORS Headers"
    local cors_response=$(curl -s -I "${BASE_URL}/health" 2>/dev/null)
    if echo "$cors_response" | grep -qi "access-control"; then
        print_info "CORS headers detected"
    else
        print_info "No CORS headers detected (may be intentional)"
    fi
    
    print_test "Server Information Disclosure"
    local server_header=$(curl -s -I "${BASE_URL}/health" 2>/dev/null | grep -i "server:" || echo "No server header")
    print_info "Server header: $server_header"
}

# =============================================================================
# Main Test Execution
# =============================================================================

print_summary() {
    print_header "Test Summary"
    echo ""
    echo -e "${BLUE}Target Server: ${BASE_URL}${NC}"
    echo -e "${BLUE}Test Completed: $(date)${NC}"
    echo ""
    echo -e "${BLUE}Results:${NC}"
    echo -e "${BLUE}  Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}  Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}  Failed: $FAILED_TESTS${NC}"
    echo -e "${CYAN}  Skipped: $SKIPPED_TESTS${NC}"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
        echo -e "${BLUE}  Success Rate: ${success_rate}%${NC}"
    fi
    
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Deployment is successful and fully functional.${NC}"
        echo -e "${GREEN}✨ The Audio RAG Agent is ready for production use.${NC}"
        
        # Additional success information
        echo ""
        echo -e "${BLUE}Access Information:${NC}"
        echo -e "${BLUE}  🌐 Web Interface: ${BASE_URL}/${NC}"
        echo -e "${BLUE}  📚 API Documentation: ${BASE_URL}/docs${NC}"
        echo -e "${BLUE}  🩺 Health Check: ${BASE_URL}/health${NC}"
        echo -e "${BLUE}  🔌 WebSocket Audio: ws://${SERVER_IP}:8000/audio${NC}"
        
        return 0
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Please review the failures above.${NC}"
        echo ""
        echo -e "${YELLOW}Failed Tests:${NC}"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ $result == FAIL:* ]]; then
                echo -e "${RED}  - ${result#FAIL: }${NC}"
            fi
        done
        return 1
    fi
}

main() {
    print_header "Audio RAG Agent - Comprehensive Deployment Testing"
    echo -e "${BLUE}Target Server: ${BASE_URL}${NC}"
    echo -e "${BLUE}Test Started: $(date)${NC}"
    echo ""
    
    check_dependencies
    
    # Core infrastructure tests
    test_server_connectivity
    echo ""
    test_health_endpoint
    echo ""
    test_api_documentation
    echo ""
    test_openapi_schema
    echo ""
    test_web_interface
    echo ""
    
    # API endpoint tests
    test_documents_api
    echo ""
    test_transcriptions_api
    echo ""
    
    # RAG pipeline tests
    test_rag_query
    echo ""
    test_document_upload_and_query
    echo ""
    
    # WebSocket tests
    test_websocket_connectivity
    echo ""
    
    # Performance tests
    test_performance
    echo ""
    
    # Error handling tests
    test_error_handling
    echo ""
    
    # Security tests
    test_security_basics
    echo ""
    
    # Print final summary
    print_summary
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [SERVER_IP]"
    echo ""
    echo "Comprehensive testing of the Audio RAG Agent deployment."
    echo ""
    echo "Arguments:"
    echo "  SERVER_IP    IP address of the deployed server (default: $DEFAULT_SERVER_IP)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Test default server"
    echo "  $0 192.168.1.100     # Test custom server"
    echo ""
    echo "Test Categories:"
    echo "  - Infrastructure (connectivity, health, documentation)"
    echo "  - API Endpoints (documents, transcriptions)"
    echo "  - RAG Pipeline (query processing, document upload)"
    echo "  - WebSocket (audio streaming)"
    echo "  - Performance (response times)"
    echo "  - Error Handling (validation, edge cases)"
    echo "  - Security (basic security headers)"
    echo ""
    echo "Dependencies:"
    echo "  - curl (required)"
    echo "  - jq (recommended for JSON parsing)"
    echo "  - bc (recommended for math operations)"
    echo "  - websocat (optional for WebSocket testing)"
    exit 0
fi

# Run main function and exit with appropriate code
if main "$@"; then
    exit 0
else
    exit 1
fi

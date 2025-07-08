#!/bin/bash

# =============================================================================
# Audio RAG Agent - Quick Test Script
# =============================================================================
# This script performs essential tests to verify deployment is working
# Usage: ./quick-test.sh [SERVER_IP]
# =============================================================================

SERVER_IP="${1:-149.28.123.26}"
BASE_URL="http://${SERVER_IP}:8000"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Quick Testing Audio RAG Agent at ${BASE_URL}"
echo "================================================"

# Test 1: Health Check
echo -n "🏥 Health Check... "
if curl -s --max-time 10 "${BASE_URL}/health" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 2: Web Interface
echo -n "🌐 Web Interface... "
if curl -s --max-time 10 "${BASE_URL}/" | grep -q "Audio RAG Tester"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 3: API Documentation
echo -n "📚 API Docs... "
if curl -s --max-time 10 "${BASE_URL}/docs" | grep -q "swagger-ui"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 4: Documents Endpoint
echo -n "📄 Documents API... "
if curl -s --max-time 10 "${BASE_URL}/documents" | grep -q "\["; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Test 5: Simple Query
echo -n "🤖 RAG Query... "
response=$(curl -s --max-time 15 -X POST \
    -H "Content-Type: application/json" \
    -d '{"query": "Hello", "include_sources": false}' \
    "${BASE_URL}/query")

if echo "$response" | grep -q '"response"'; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

echo ""
echo "🎯 Quick test completed!"
echo "For comprehensive testing, run: ./test-deployment.sh"

#!/bin/bash

# Pre-deployment verification script
# Checks if everything is ready for deployment

echo "🔍 Pre-deployment verification for Anna Webinar Demo"
echo "================================================="

# Check 1: Local environment
echo "1. Checking local environment..."
if [ ! -f "package.json" ]; then
    echo "   ❌ Not in React app directory"
    exit 1
else
    echo "   ✅ In correct directory"
fi

# Check 2: Node modules
if [ ! -d "node_modules" ]; then
    echo "   ❌ Dependencies not installed. Run: npm install"
    exit 1
else
    echo "   ✅ Dependencies installed"
fi

# Check 3: Docker availability
if ! command -v docker &> /dev/null; then
    echo "   ❌ Docker not installed"
    exit 1
else
    echo "   ✅ Docker available"
fi

# Check 4: SSH connection to VPS
echo "2. Testing VPS connection..."
VPS_IP="45.32.212.233"
VPS_USER="root"

if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${VPS_USER}@${VPS_IP} "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "   ❌ Cannot connect to VPS"
    echo "   💡 Make sure SSH key is configured for ${VPS_USER}@${VPS_IP}"
    exit 1
else
    echo "   ✅ VPS connection successful"
fi

# Check 5: Backend availability (optional)
echo "3. Checking backend availability..."
if curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/health 2>/dev/null | grep -q "200"; then
    echo "   ✅ Local backend is running"
elif curl -s -o /dev/null -w '%{http_code}' http://${VPS_IP}:8000/health 2>/dev/null | grep -q "200"; then
    echo "   ✅ Remote backend is running"
else
    echo "   ⚠️  No backend detected (will use production config)"
fi

echo ""
echo "🎯 All checks passed! Ready for deployment."
echo ""
echo "Next steps:"
echo "1. Run: ./deploy-to-vultr.sh"
echo "2. Test: ./test-deployment.sh"
echo "3. Access: http://${VPS_IP}:3000"

#!/bin/bash

# Production Deployment Verification Script
# This script verifies that the Audio RAG Agent is ready for Vultr deployment

set -e

echo "🔍 Verifying Audio RAG Agent deployment readiness..."
echo ""

# Check if required files exist
echo "📋 Checking required files..."
required_files=(
    "src/main.py"
    "src/api/routes.py"
    "src/core/rag_pipeline.py"
    "src/core/audio_processor.py"
    "static/index.html"
    "requirements.txt"
    "Dockerfile"
    "docker-compose.yml"
    ".env.production"
    "deploy-vultr.sh"
    "DEPLOYMENT-CHECKLIST.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

echo ""
echo "🐳 Checking Docker configuration..."

# Check if Dockerfile exists and has proper structure
if [ -f "Dockerfile" ]; then
    if grep -q "FROM python:" Dockerfile && grep -q "COPY requirements.txt" Dockerfile && grep -q "CMD.*python.*main.py" Dockerfile; then
        echo "✅ Dockerfile structure valid"
    else
        echo "❌ Dockerfile structure invalid"
        exit 1
    fi
else
    echo "❌ Dockerfile missing"
    exit 1
fi

# Check docker-compose syntax (skip if docker not available)
if command -v docker-compose >/dev/null 2>&1; then
    if docker-compose config >/dev/null 2>&1; then
        echo "✅ docker-compose.yml syntax valid"
    else
        echo "❌ docker-compose.yml syntax invalid"
        exit 1
    fi
else
    # Just check basic structure if docker-compose not available
    if grep -q "version:" docker-compose.yml && grep -q "services:" docker-compose.yml && grep -q "app:" docker-compose.yml; then
        echo "✅ docker-compose.yml structure valid"
    else
        echo "❌ docker-compose.yml structure invalid"
        exit 1
    fi
fi

echo ""
echo "📝 Checking environment configuration..."

# Check if .env.production has required variables
required_env_vars=(
    "GROQ_API_KEY"
    "HOST"
    "PORT"
    "ENVIRONMENT"
    "CHROMA_PERSIST_DIRECTORY"
)

if [ -f ".env.production" ]; then
    for var in "${required_env_vars[@]}"; do
        if grep -q "^$var=" .env.production; then
            echo "✅ $var configured"
        else
            echo "❌ $var missing from .env.production"
            exit 1
        fi
    done
else
    echo "❌ .env.production file missing"
    exit 1
fi

echo ""
echo "🌐 Checking API endpoints..."

# Check if routes.py has all required endpoints
required_endpoints=(
    "health"
    "query"
    "documents"
    "transcriptions"
    "audio"
)

for endpoint in "${required_endpoints[@]}"; do
    if grep -q "$endpoint" src/api/routes.py; then
        echo "✅ /$endpoint endpoint defined"
    else
        echo "❌ /$endpoint endpoint missing"
        exit 1
    fi
done

# Check for DELETE endpoints specifically
if grep -q "@router.delete.*documents" src/api/routes.py; then
    echo "✅ DELETE /documents/{document_id} endpoint defined"
else
    echo "❌ DELETE /documents/{document_id} endpoint missing"
    exit 1
fi

if grep -q "@router.delete.*transcriptions" src/api/routes.py; then
    echo "✅ DELETE /transcriptions/{transcription_id} endpoint defined"
else
    echo "❌ DELETE /transcriptions/{transcription_id} endpoint missing"
    exit 1
fi

echo ""
echo "🎨 Checking web UI features..."

# Check if index.html has required features
ui_features=(
    "loadDocuments"
    "loadTranscriptions"
    "deleteDocument"
    "deleteTranscription"
    "documentsTable"
    "transcriptionsTable"
)

for feature in "${ui_features[@]}"; do
    if grep -q "$feature" static/index.html; then
        echo "✅ $feature implemented"
    else
        echo "❌ $feature missing from UI"
        exit 1
    fi
done

echo ""
echo "🔒 Checking deployment scripts..."

# Check if deployment script is executable
if [ -x "deploy-vultr.sh" ]; then
    echo "✅ deploy-vultr.sh is executable"
else
    echo "⚠️  Making deploy-vultr.sh executable"
    chmod +x deploy-vultr.sh
fi

# Check if deployment script has required sections
deployment_sections=(
    "Installing Docker"
    "Installing Nginx"
    "Configuring Nginx"
    "Setting up systemd"
    "Configuring firewall"
)

for section in "${deployment_sections[@]}"; do
    if grep -q "$section" deploy-vultr.sh; then
        echo "✅ $section configured in deployment script"
    else
        echo "❌ $section missing from deployment script"
        exit 1
    fi
done

echo ""
echo "📊 Checking monitoring and backup scripts..."

if [ -f "monitor.sh" ]; then
    echo "✅ monitor.sh exists"
    if [ -x "monitor.sh" ]; then
        echo "✅ monitor.sh is executable"
    else
        echo "⚠️  Making monitor.sh executable"
        chmod +x monitor.sh
    fi
else
    echo "❌ monitor.sh missing"
    exit 1
fi

if [ -f "backup.sh" ]; then
    echo "✅ backup.sh exists"
    if [ -x "backup.sh" ]; then
        echo "✅ backup.sh is executable"
    else
        echo "⚠️  Making backup.sh executable"
        chmod +x backup.sh
    fi
else
    echo "❌ backup.sh missing"
    exit 1
fi

echo ""
echo "🎉 All deployment readiness checks passed!"
echo ""
echo "📋 Next steps for Vultr deployment:"
echo "1. Create a Vultr VPS (minimum 2GB RAM, 50GB disk)"
echo "2. Upload these files to your server"
echo "3. Copy .env.production to .env and configure with your actual values"
echo "4. Run: chmod +x deploy-vultr.sh && ./deploy-vultr.sh"
echo "5. Follow the DEPLOYMENT-CHECKLIST.md for complete setup"
echo ""
echo "🌟 Your Audio RAG Agent is ready for production deployment!"

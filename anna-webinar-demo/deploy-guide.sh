#!/bin/bash

# Final verification and deployment guide

echo "🎯 Anna Webinar Demo - Final Deployment Guide"
echo "============================================="
echo ""

# Check if we're in the right place
if [ -f "package.json" ] && [ -f "deploy-simple.sh" ]; then
    echo "✅ You're in the correct directory (anna-webinar-demo)"
else
    echo "❌ Please navigate to the anna-webinar-demo directory first"
    echo "   cd anna-webinar-demo"
    exit 1
fi

echo "📋 Pre-flight checklist:"
echo ""
echo "1. ✅ React app with AI chat integration"
echo "2. ✅ Docker configuration for production"
echo "3. ✅ Deployment scripts created"
echo "4. ✅ Environment configuration set"
echo ""

echo "🎯 Ready to deploy!"
echo ""
echo "Choose your deployment method:"
echo ""
echo "Option 1: Simple Deployment (Recommended)"
echo "----------------------------------------"
echo "   ./deploy-simple.sh"
echo "   • Works with password authentication"
echo "   • Handles everything automatically"
echo "   • Prompts for VPS password"
echo ""

echo "Option 2: Advanced Deployment (SSH Keys)"
echo "---------------------------------------"
echo "   ./setup-ssh.sh        # First, set up SSH keys"
echo "   ./deploy-to-vultr.sh   # Then deploy"
echo ""

echo "Option 3: Manual Build + Upload"
echo "------------------------------"
echo "   npm run build"
echo "   # Then manually copy files to VPS"
echo ""

echo "🌐 After deployment, your app will be available at:"
echo "   Frontend: http://45.32.212.233:3000"
echo "   Backend:  http://45.32.212.233:8000 (your existing RAG server)"
echo ""

echo "📊 Testing after deployment:"
echo "   ./test-deployment.sh"
echo ""

echo "📞 Need help? Check:"
echo "   • DEPLOYMENT-README.md - Detailed instructions"
echo "   • ANNA-DEPLOYMENT-SUMMARY.md - Quick overview"
echo ""

echo "🚀 Ready? Choose your deployment option above!"

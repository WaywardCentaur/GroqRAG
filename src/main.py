"""
Main application entry point for the Real-Time Audio RAG Agent.
"""
import os
from dotenv import load_dotenv
import uvicorn
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from api.routes import router as api_router

# Load environment variables
load_dotenv()

# Create FastAPI application
app = FastAPI(
    title="Real-Time Audio RAG Agent",
    description="AI agent for real-time audio transcription and RAG-based question answering",
    version="1.0.0"
)

# Configure CORS
cors_origins = os.getenv("CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Include API routes
app.include_router(api_router)

# Redirect root to the test app
@app.get("/")
async def redirect_to_test_app():
    return FileResponse("static/index.html")

if __name__ == "__main__":
    # Get configuration from environment
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    workers = int(os.getenv("WORKERS", "1"))
    log_level = os.getenv("LOG_LEVEL", "info").lower()
    
    # Print startup information
    print("🚀 Starting Real-Time Audio RAG Agent")
    print(f"   🌐 Host: {host}")
    print(f"   🔌 Port: {port}")
    print(f"   🏭 Workers: {workers}")
    print(f"   📝 Log Level: {log_level}")
    print(f"   🌍 Environment: {os.getenv('ENVIRONMENT', 'development')}")
    print("=" * 50)
    
    # Development vs Production
    if os.getenv("ENVIRONMENT") == "production":
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            workers=workers,
            log_level=log_level,
            access_log=True
        )
    else:
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            reload=True,
            log_level=log_level
        )

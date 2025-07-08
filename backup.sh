#!/bin/bash

# Backup Script for Audio RAG Agent
# This script creates backups of application data and configuration

APP_DIR="/opt/audio-rag-agent"
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting backup process..."

# Backup ChromaDB data
if [ -d "$APP_DIR/data/chromadb" ]; then
    log "Backing up ChromaDB data..."
    tar -czf "$BACKUP_DIR/chromadb_$DATE.tar.gz" -C "$APP_DIR" data/chromadb
    log "ChromaDB backup completed: chromadb_$DATE.tar.gz"
else
    log "WARNING: ChromaDB data directory not found"
fi

# Backup configuration files
log "Backing up configuration files..."
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" -C "$APP_DIR" \
    .env \
    docker-compose.yml \
    requirements.txt \
    Dockerfile \
    2>/dev/null

log "Configuration backup completed: config_$DATE.tar.gz"

# Backup logs (last 7 days)
if [ -d "$APP_DIR/logs" ]; then
    log "Backing up recent logs..."
    find "$APP_DIR/logs" -name "*.log" -mtime -7 -print0 | \
        tar -czf "$BACKUP_DIR/logs_$DATE.tar.gz" --null -T -
    log "Logs backup completed: logs_$DATE.tar.gz"
fi

# Clean up old backups (keep last 30 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
log "Old backups cleaned up"

# Show backup summary
log "Backup summary:"
ls -lh "$BACKUP_DIR"/*$DATE.tar.gz 2>/dev/null | while read line; do
    log "  $line"
done

log "Backup process completed successfully"

# Optional: Upload to external storage
# Uncomment and configure for your storage solution
# rsync -av "$BACKUP_DIR/" user@backup-server:/backups/audio-rag-agent/
# aws s3 sync "$BACKUP_DIR/" s3://your-backup-bucket/audio-rag-agent/

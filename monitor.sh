#!/bin/bash

# Production Monitoring Script for Audio RAG Agent
# This script monitors the health and performance of the deployed application

APP_DIR="/opt/audio-rag-agent"
LOG_FILE="/var/log/audio-rag-monitor.log"

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a $LOG_FILE
}

# Function to check application health
check_health() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
    if [ "$response" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check Docker containers
check_containers() {
    cd $APP_DIR
    local running=$(docker-compose ps -q app | wc -l)
    if [ "$running" -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

# Function to get application stats
get_stats() {
    curl -s http://localhost:8000/debug/stats 2>/dev/null || echo '{"error": "stats unavailable"}'
}

# Function to restart application
restart_app() {
    log "ALERT: Restarting application due to health check failure"
    cd $APP_DIR
    docker-compose restart app
    sleep 30
    
    if check_health; then
        log "SUCCESS: Application restarted successfully"
        # Send notification (add your notification method here)
        # curl -X POST "https://hooks.slack.com/..." -d '{"text":"Audio RAG Agent restarted on Vultr"}'
    else
        log "ERROR: Application restart failed"
        # Send critical alert
    fi
}

# Function to check disk space
check_disk_space() {
    local usage=$(df /opt | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$usage" -gt 85 ]; then
        log "WARNING: Disk usage is ${usage}%"
        # Clean up old logs
        find $APP_DIR/logs -name "*.log" -mtime +7 -delete
        docker system prune -f
    fi
}

# Function to check memory usage
check_memory() {
    local mem_usage=$(free | awk 'FNR==2{printf "%.0f", $3/$2*100}')
    if [ "$mem_usage" -gt 85 ]; then
        log "WARNING: Memory usage is ${mem_usage}%"
    fi
}

# Main monitoring loop
main() {
    log "Starting monitoring check..."
    
    # Check if containers are running
    if ! check_containers; then
        log "ERROR: Docker containers not running"
        restart_app
        exit 1
    fi
    
    # Check application health
    if ! check_health; then
        log "ERROR: Health check failed"
        restart_app
        exit 1
    fi
    
    # Get and log current stats
    local stats=$(get_stats)
    log "INFO: Application stats: $stats"
    
    # Check system resources
    check_disk_space
    check_memory
    
    log "INFO: Monitoring check completed successfully"
}

# Handle command line arguments
case "${1:-monitor}" in
    "monitor")
        main
        ;;
    "restart")
        restart_app
        ;;
    "logs")
        cd $APP_DIR && docker-compose logs -f app
        ;;
    "stats")
        get_stats | jq .
        ;;
    "status")
        echo "Container Status:"
        cd $APP_DIR && docker-compose ps
        echo -e "\nHealth Check:"
        if check_health; then
            echo "✅ Application is healthy"
        else
            echo "❌ Application is unhealthy"
        fi
        echo -e "\nSystem Resources:"
        echo "Memory: $(free -h | awk 'NR==2{printf "%.1f/%.1fG (%.0f%%)", $3/1024/1024,$2/1024/1024,$3*100/$2}')"
        echo "Disk: $(df -h /opt | awk 'NR==2{printf "%s/%s (%s)", $3,$2,$5}')"
        ;;
    *)
        echo "Usage: $0 {monitor|restart|logs|stats|status}"
        echo "  monitor  - Run health checks and monitoring"
        echo "  restart  - Restart the application"
        echo "  logs     - Show application logs"
        echo "  stats    - Show application statistics"
        echo "  status   - Show overall system status"
        exit 1
        ;;
esac

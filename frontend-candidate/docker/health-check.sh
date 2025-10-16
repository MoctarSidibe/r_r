#!/bin/sh

# Health check script for Student Frontend
set -e

# Configuration
HEALTH_CHECK_URL="http://localhost:3000/health"
API_URL=${REACT_APP_API_URL:-"http://api.dgtt.local"}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if the frontend is responding
check_frontend() {
    log "Checking frontend endpoint..."
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
        success "Frontend is healthy"
        return 0
    else
        error "Frontend is not responding"
        return 1
    fi
}

# Check if backend API is accessible
check_backend() {
    log "Checking backend API connectivity..."
    if curl -f -s "$API_URL/health" > /dev/null; then
        success "Backend API is accessible"
        return 0
    else
        error "Backend API is not accessible"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    DISK_USAGE=$(df /usr/share/nginx/html | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 90 ]; then
        success "Disk space is sufficient ($DISK_USAGE% used)"
        return 0
    else
        error "Disk space is low ($DISK_USAGE% used)"
        return 1
    fi
}

# Main health check
main() {
    log "Starting student frontend health check..."
    
    local exit_code=0
    
    # Run all checks
    check_disk_space || exit_code=1
    check_frontend || exit_code=1
    check_backend || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        success "All health checks passed"
        log "Student frontend is healthy"
    else
        error "Some health checks failed"
        log "Student frontend may have issues"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"

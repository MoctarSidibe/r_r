#!/bin/sh

# Health check script for Laravel application
# Checks database connectivity, Redis, and HTTP endpoints

set -e

# Configuration
HEALTH_CHECK_URL="http://localhost:8000/health"
DB_HOST=${DB_HOST:-postgres-primary}
DB_PORT=${DB_PORT:-5432}
REDIS_HOST=${REDIS_HOST:-redis-primary}
REDIS_PORT=${REDIS_PORT:-6379}

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

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if the application is responding
check_http() {
    log "Checking HTTP endpoint..."
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
        success "HTTP endpoint is healthy"
        return 0
    else
        error "HTTP endpoint is not responding"
        return 1
    fi
}

# Check database connectivity
check_database() {
    log "Checking database connectivity..."
    if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" > /dev/null 2>&1; then
        success "Database is accessible"
        return 0
    else
        error "Database is not accessible"
        return 1
    fi
}

# Check Redis connectivity
check_redis() {
    log "Checking Redis connectivity..."
    if nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; then
        success "Redis is accessible"
        return 0
    else
        warning "Redis is not accessible"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    DISK_USAGE=$(df /var/www/html | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 90 ]; then
        success "Disk space is sufficient ($DISK_USAGE% used)"
        return 0
    else
        error "Disk space is low ($DISK_USAGE% used)"
        return 1
    fi
}

# Check memory usage
check_memory() {
    log "Checking memory usage..."
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$MEMORY_USAGE" -lt 90 ]; then
        success "Memory usage is acceptable ($MEMORY_USAGE% used)"
        return 0
    else
        warning "Memory usage is high ($MEMORY_USAGE% used)"
        return 1
    fi
}

# Main health check
main() {
    log "Starting health check..."
    
    local exit_code=0
    
    # Run all checks
    check_disk_space || exit_code=1
    check_memory || exit_code=1
    check_database || exit_code=1
    check_redis || exit_code=1
    check_http || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        success "All health checks passed"
        log "Application is healthy"
    else
        error "Some health checks failed"
        log "Application may have issues"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"

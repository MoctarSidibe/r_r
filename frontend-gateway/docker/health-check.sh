#!/bin/sh

# Health check script for Frontend Gateway
set -e

# Configuration
HEALTH_CHECK_URL="http://localhost:80/health"
ADMIN_URL="http://localhost:80/admin"
STUDENT_URL="http://localhost:80/student"

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

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if the gateway is responding
check_gateway() {
    log "Checking gateway endpoint..."
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
        success "Gateway is healthy"
        return 0
    else
        error "Gateway is not responding"
        return 1
    fi
}

# Check admin micro frontend routing
check_admin_routing() {
    log "Checking admin micro frontend routing..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ADMIN_URL")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        success "Admin routing is working (HTTP $HTTP_CODE)"
        return 0
    else
        warning "Admin routing returned HTTP $HTTP_CODE"
        return 1
    fi
}

# Check student micro frontend routing
check_student_routing() {
    log "Checking student micro frontend routing..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$STUDENT_URL")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        success "Student routing is working (HTTP $HTTP_CODE)"
        return 0
    else
        warning "Student routing returned HTTP $HTTP_CODE"
        return 1
    fi
}

# Check nginx configuration
check_nginx_config() {
    log "Checking nginx configuration..."
    if nginx -t > /dev/null 2>&1; then
        success "Nginx configuration is valid"
        return 0
    else
        error "Nginx configuration is invalid"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    DISK_USAGE=$(df /etc/nginx | awk 'NR==2 {print $5}' | sed 's/%//')
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
    log "Starting frontend gateway health check..."
    
    local exit_code=0
    
    # Run all checks
    check_disk_space || exit_code=1
    check_nginx_config || exit_code=1
    check_gateway || exit_code=1
    check_admin_routing || exit_code=1
    check_student_routing || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        success "All health checks passed"
        log "Frontend gateway is healthy"
    else
        error "Some health checks failed"
        log "Frontend gateway may have issues"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"

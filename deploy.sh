#!/bin/bash

# DGTT Auto-École Deployment Script
# This script deploys all services to the Hetzner server

set -e

echo "🚀 Starting DGTT Auto-École Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project root directory."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Building and starting all services..."

# Build and start all services
docker-compose up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service status
print_status "Checking service status..."
docker-compose ps

# Test service health
print_status "Testing service health..."

# Test Consul
if curl -f http://localhost:8500/v1/status/leader > /dev/null 2>&1; then
    print_success "Consul is healthy"
else
    print_warning "Consul health check failed"
fi

# Test PostgreSQL
if docker-compose exec -T postgres pg_isready -U dgtt_user -d dgtt_auto_ecole > /dev/null 2>&1; then
    print_success "PostgreSQL is healthy"
else
    print_warning "PostgreSQL health check failed"
fi

# Test Redis
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_success "Redis is healthy"
else
    print_warning "Redis health check failed"
fi

# Test RabbitMQ
if curl -f http://localhost:15672 > /dev/null 2>&1; then
    print_success "RabbitMQ is healthy"
else
    print_warning "RabbitMQ health check failed"
fi

# Test Traefik
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    print_success "Traefik is healthy"
else
    print_warning "Traefik health check failed"
fi

# Test Backend (if running)
if docker-compose ps backend | grep -q "Up"; then
    if curl -f http://localhost/api/health > /dev/null 2>&1; then
        print_success "Backend API is healthy"
    else
        print_warning "Backend API health check failed"
    fi
else
    print_warning "Backend service is not running"
fi

# Test Frontend Gateway (if running)
if docker-compose ps frontend-gateway | grep -q "Up"; then
    if curl -f http://localhost/health > /dev/null 2>&1; then
        print_success "Frontend Gateway is healthy"
    else
        print_warning "Frontend Gateway health check failed"
    fi
else
    print_warning "Frontend Gateway service is not running"
fi

# Test Frontend Admin (if running)
if docker-compose ps frontend-admin | grep -q "Up"; then
    if curl -f http://localhost/admin/health > /dev/null 2>&1; then
        print_success "Frontend Admin is healthy"
    else
        print_warning "Frontend Admin health check failed"
    fi
else
    print_warning "Frontend Admin service is not running"
fi

# Test Frontend Candidate (if running)
if docker-compose ps frontend-candidate | grep -q "Up"; then
    if curl -f http://localhost/candidate/health > /dev/null 2>&1; then
        print_success "Frontend Candidate is healthy"
    else
        print_warning "Frontend Candidate health check failed"
    fi
else
    print_warning "Frontend Candidate service is not running"
fi

print_status "Deployment completed!"

echo ""
echo "🌐 Service URLs:"
echo "  - Main Gateway: http://168.119.123.247"
echo "  - Admin Interface: http://168.119.123.247/admin"
echo "  - Candidate Interface: http://168.119.123.247/candidate"
echo "  - API Backend: http://168.119.123.247/api"
echo "  - Traefik Dashboard: http://168.119.123.247:8080"
echo "  - Consul UI: http://168.119.123.247:8500"
echo "  - RabbitMQ Management: http://168.119.123.247:15672"
echo ""
echo "📊 Database Connection:"
echo "  - Host: 168.119.123.247"
echo "  - Port: 5432"
echo "  - Database: dgtt_auto_ecole"
echo "  - User: dgtt_user"
echo "  - Password: dgtt_password_secure_2024"
echo ""
echo "🔧 Useful Commands:"
echo "  - View logs: docker-compose logs [service-name]"
echo "  - Restart service: docker-compose restart [service-name]"
echo "  - Stop all services: docker-compose down"
echo "  - View service status: docker-compose ps"
echo ""

print_success "🎉 DGTT Auto-École deployment completed successfully!"

# DGTT Auto-École - Comprehensive Test Plan

## 🎯 **Test Overview**
This document outlines the complete testing strategy for the DGTT Auto-École microservices application deployed on Hetzner server.

## 🏗️ **System Architecture**
- **Frontend Gateway**: Nginx reverse proxy for micro frontends
- **Frontend Admin**: React application for administrators
- **Frontend Candidate**: React application for candidates
- **Backend API**: Laravel REST API
- **Database**: PostgreSQL
- **Cache**: Redis
- **Message Queue**: RabbitMQ
- **Service Discovery**: Consul
- **Reverse Proxy**: Traefik

## 🧪 **Test Categories**

### 1. **Infrastructure Tests**

#### 1.1 Service Health Checks
```bash
# Check all services are running
docker compose ps

# Expected: All services should be "Up" and "healthy"
```

#### 1.2 Network Connectivity
```bash
# Test internal network connectivity
docker compose exec backend ping frontend-admin
docker compose exec backend ping frontend-candidate
docker compose exec backend ping postgres
docker compose exec backend ping redis
docker compose exec backend ping rabbitmq
```

#### 1.3 Port Accessibility
```bash
# Test external port access
curl -I http://168.119.123.247:8500  # Consul UI
curl -I http://168.119.123.247:15672 # RabbitMQ Management
curl -I http://168.119.123.247:8080  # Traefik Dashboard
```

### 2. **Backend API Tests**

#### 2.1 Health Endpoints
```bash
# Test health endpoints
curl http://168.119.123.247/api/health
curl http://168.119.123.247/health

# Expected: JSON response with "healthy" status
```

#### 2.2 Database Connectivity
```bash
# Test database connection
docker compose exec backend php artisan tinker
# In tinker:
DB::connection()->getPdo();
# Expected: PDO connection object
```

#### 2.3 Cache System
```bash
# Test Redis cache
docker compose exec backend php artisan tinker
# In tinker:
Cache::put('test', 'value', 60);
Cache::get('test');
# Expected: 'value'
```

#### 2.4 Message Queue
```bash
# Test RabbitMQ connection
docker compose exec backend php artisan tinker
# In tinker:
Queue::push('test-job', ['data' => 'test']);
# Expected: Job queued successfully
```

### 3. **Frontend Tests**

#### 3.1 Homepage Test
```bash
# Test main homepage
curl -I http://168.119.123.247/

# Expected: 200 OK with HTML content
```

#### 3.2 Admin Panel Test
```bash
# Test admin frontend
curl -I http://168.119.123.247/admin

# Expected: 200 OK with React application
```

#### 3.3 Candidate Portal Test
```bash
# Test candidate frontend
curl -I http://168.119.123.247/candidate

# Expected: 200 OK with React application
```

#### 3.4 Static Assets Test
```bash
# Test CSS/JS loading
curl -I http://168.119.123.247/admin/static/css/main.css
curl -I http://168.119.123.247/candidate/static/js/main.js

# Expected: 200 OK with proper MIME types
```

### 4. **Traefik Routing Tests**

#### 4.1 Path Routing
```bash
# Test path-based routing
curl -I http://168.119.123.247/
curl -I http://168.119.123.247/admin
curl -I http://168.119.123.247/candidate
curl -I http://168.119.123.247/api/health

# Expected: All return 200 OK
```

#### 4.2 Path Stripping
```bash
# Test that path prefixes are stripped
curl http://168.119.123.247/admin/health
curl http://168.119.123.247/candidate/health

# Expected: Health check responses from respective services
```

### 5. **Security Tests**

#### 5.1 Security Headers
```bash
# Test security headers
curl -I http://168.119.123.247/

# Expected headers:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
# Referrer-Policy: strict-origin-when-cross-origin
```

#### 5.2 HTTPS Redirect (if configured)
```bash
# Test HTTPS redirect
curl -I http://168.119.123.247/

# Expected: 301 redirect to HTTPS (if SSL configured)
```

### 6. **Performance Tests**

#### 6.1 Response Times
```bash
# Test response times
time curl http://168.119.123.247/api/health
time curl http://168.119.123.247/admin
time curl http://168.119.123.247/candidate

# Expected: < 2 seconds for all endpoints
```

#### 6.2 Load Testing
```bash
# Basic load test
for i in {1..10}; do
  curl -s http://168.119.123.247/api/health &
done
wait

# Expected: All requests complete successfully
```

### 7. **Browser Tests**

#### 7.1 Homepage Navigation
- Visit http://168.119.123.247/
- Verify homepage loads with navigation buttons
- Click "Espace Administrateur" → should go to /admin
- Click "Espace Candidat" → should go to /candidate

#### 7.2 Admin Panel
- Visit http://168.119.123.247/admin
- Verify React application loads
- Check browser console for errors
- Verify CSS/JS files load with correct MIME types

#### 7.3 Candidate Portal
- Visit http://168.119.123.247/candidate
- Verify React application loads
- Check browser console for errors
- Verify CSS/JS files load with correct MIME types

### 8. **Database Tests**

#### 8.1 Database Schema
```bash
# Check database tables
docker compose exec postgres psql -U dgtt_user -d dgtt_auto_ecole -c "\dt"

# Expected: List of tables from init scripts
```

#### 8.2 Data Integrity
```bash
# Test data operations
docker compose exec backend php artisan tinker
# In tinker:
User::count();
# Expected: Number of users (if any seeded)
```

### 9. **Monitoring Tests**

#### 9.1 Traefik Dashboard
- Visit http://168.119.123.247:8080
- Verify all services are visible
- Check routing rules
- Monitor request metrics

#### 9.2 Consul UI
- Visit http://168.119.123.247:8500
- Verify service discovery
- Check service health

#### 9.3 RabbitMQ Management
- Visit http://168.119.123.247:15672
- Default credentials: guest/guest
- Verify queue management

### 10. **Error Handling Tests**

#### 10.1 404 Errors
```bash
# Test non-existent endpoints
curl -I http://168.119.123.247/nonexistent
curl -I http://168.119.123.247/admin/nonexistent

# Expected: 404 Not Found
```

#### 10.2 Service Failures
```bash
# Test service resilience
docker compose stop frontend-admin
curl -I http://168.119.123.247/admin
# Expected: 503 Service Unavailable or timeout

docker compose start frontend-admin
curl -I http://168.119.123.247/admin
# Expected: 200 OK after service restart
```

## 🚀 **Automated Test Script**

```bash
#!/bin/bash
# DGTT Auto-École Automated Test Script

echo "🧪 Starting DGTT Auto-École Test Suite..."

# Test 1: Service Health
echo "1. Testing service health..."
docker compose ps | grep -q "Up.*healthy" || echo "❌ Some services not healthy"

# Test 2: Backend API
echo "2. Testing backend API..."
curl -s http://168.119.123.247/api/health | grep -q "healthy" || echo "❌ Backend API not responding"

# Test 3: Frontend Services
echo "3. Testing frontend services..."
curl -s -I http://168.119.123.247/ | grep -q "200\|301" || echo "❌ Homepage not accessible"
curl -s -I http://168.119.123.247/admin | grep -q "200" || echo "❌ Admin panel not accessible"
curl -s -I http://168.119.123.247/candidate | grep -q "200" || echo "❌ Candidate portal not accessible"

# Test 4: Database
echo "4. Testing database..."
docker compose exec backend php artisan tinker --execute="DB::connection()->getPdo();" || echo "❌ Database connection failed"

# Test 5: Cache
echo "5. Testing cache..."
docker compose exec backend php artisan tinker --execute="Cache::put('test', 'value'); echo Cache::get('test');" | grep -q "value" || echo "❌ Cache not working"

echo "✅ Test suite completed!"
```

## 📊 **Test Results Template**

| Test Category | Status | Notes |
|---------------|--------|-------|
| Infrastructure | ✅/❌ | All services running |
| Backend API | ✅/❌ | Health endpoints working |
| Frontend Services | ✅/❌ | All frontends accessible |
| Traefik Routing | ✅/❌ | Path routing working |
| Security Headers | ✅/❌ | Security headers present |
| Performance | ✅/❌ | Response times acceptable |
| Browser Tests | ✅/❌ | No console errors |
| Database | ✅/❌ | Connection and queries working |
| Monitoring | ✅/❌ | Dashboards accessible |
| Error Handling | ✅/❌ | Proper error responses |

## 🎯 **Success Criteria**

- ✅ All services running and healthy
- ✅ All endpoints accessible via Traefik
- ✅ No console errors in browser
- ✅ Proper MIME types for static assets
- ✅ Security headers present
- ✅ Response times < 2 seconds
- ✅ Database connectivity working
- ✅ Cache system functional
- ✅ Message queue operational

## 🔧 **Troubleshooting Guide**

### Common Issues:
1. **404 Errors**: Check Traefik routing configuration
2. **MIME Type Errors**: Verify path stripping middleware
3. **Service Restarts**: Check container logs for errors
4. **Database Connection**: Verify PostgreSQL is running
5. **Cache Issues**: Check Redis connectivity

### Debug Commands:
```bash
# Check service logs
docker compose logs [service-name]

# Check Traefik configuration
docker compose exec traefik cat /etc/traefik/traefik.yml

# Test internal connectivity
docker compose exec backend curl http://frontend-admin/health
```

---

**Last Updated**: October 17, 2025  
**Version**: 1.0  
**Environment**: Production (Hetzner Server)

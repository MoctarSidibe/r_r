#!/bin/bash

# DGTT Auto-École - Enhanced Backup Script
# Automated backup with compression, encryption, and retention

set -e

# Configuration
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY:-"dgtt-backup-key-2024"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p $BACKUP_DIR

log "🔄 Starting backup process..."

# 1. Database backup
log "📊 Creating database backup..."
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
    --verbose \
    --no-password \
    --format=custom \
    --compress=9 \
    --file=$BACKUP_DIR/db_backup_$DATE.dump

if [ $? -eq 0 ]; then
    success "Database backup created: db_backup_$DATE.dump"
else
    error "Database backup failed"
    exit 1
fi

# 2. Application files backup (if volume mounted)
if [ -d "/var/www/html" ]; then
    log "📁 Creating application files backup..."
    tar -czf $BACKUP_DIR/app_files_$DATE.tar.gz \
        --exclude='vendor' \
        --exclude='node_modules' \
        --exclude='storage/logs' \
        --exclude='storage/framework/cache' \
        --exclude='.git' \
        /var/www/html/
    
    if [ $? -eq 0 ]; then
        success "Application files backup created: app_files_$DATE.tar.gz"
    else
        warning "Application files backup failed"
    fi
fi

# 3. Configuration files backup
log "⚙️ Creating configuration backup..."
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    /etc/ssl/certs/ \
    /etc/letsencrypt/ \
    /opt/dgtt-autoecole/.env \
    /opt/dgtt-autoecole/docker-compose.yml \
    /opt/dgtt-autoecole/monitoring/ \
    2>/dev/null || warning "Some configuration files not found"

if [ $? -eq 0 ]; then
    success "Configuration backup created: config_$DATE.tar.gz"
fi

# 4. Encrypt sensitive backups
log "🔐 Encrypting sensitive backups..."
for file in $BACKUP_DIR/*_$DATE.*; do
    if [ -f "$file" ]; then
        gpg --symmetric --cipher-algo AES256 --passphrase "$ENCRYPTION_KEY" --batch --yes "$file"
        if [ $? -eq 0 ]; then
            rm "$file"  # Remove unencrypted version
            success "Encrypted: $(basename $file)"
        else
            warning "Failed to encrypt: $(basename $file)"
        fi
    fi
done

# 5. Create backup manifest
log "📋 Creating backup manifest..."
cat > $BACKUP_DIR/manifest_$DATE.txt << EOF
DGTT Auto-École Backup Manifest
================================
Date: $(date)
Hostname: $(hostname)
Backup Type: Full System Backup

Files Created:
$(ls -la $BACKUP_DIR/*_$DATE.*.gpg 2>/dev/null || echo "No encrypted files found")

Database Info:
- Database: $DB_NAME
- Host: $DB_HOST
- User: $DB_USER

Application Info:
- Application Path: /var/www/html
- Configuration Path: /opt/dgtt-autoecole

Retention Policy:
- Keep backups for: $RETENTION_DAYS days
- Next cleanup: $(date -d "+$RETENTION_DAYS days" +%Y-%m-%d)

Backup Size:
$(du -sh $BACKUP_DIR/*_$DATE.*.gpg 2>/dev/null || echo "No backup files found")

EOF

# 6. Upload to cloud storage (if configured)
if [ ! -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$AWS_S3_BUCKET" ]; then
    log "☁️ Uploading to S3..."
    aws s3 cp $BACKUP_DIR/ s3://$AWS_S3_BUCKET/backups/ --recursive --exclude "*" --include "*_$DATE.*"
    if [ $? -eq 0 ]; then
        success "Backups uploaded to S3"
    else
        warning "S3 upload failed"
    fi
fi

# 7. Cleanup old backups
log "🧹 Cleaning up old backups..."
find $BACKUP_DIR -name "*.gpg" -type f -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "manifest_*.txt" -type f -mtime +$RETENTION_DAYS -delete

# Count remaining backups
remaining_count=$(find $BACKUP_DIR -name "*.gpg" -type f | wc -l)
success "Old backups cleaned up. $remaining_count backups remaining."

# 8. Health check
log "🏥 Performing backup health check..."
if [ -f "$BACKUP_DIR/db_backup_$DATE.dump.gpg" ]; then
    # Test database backup integrity
    gpg --decrypt --passphrase "$ENCRYPTION_KEY" --batch --yes "$BACKUP_DIR/db_backup_$DATE.dump.gpg" | pg_restore --list > /dev/null
    if [ $? -eq 0 ]; then
        success "Database backup integrity verified"
    else
        error "Database backup integrity check failed"
        exit 1
    fi
else
    error "Database backup file not found"
    exit 1
fi

# 9. Send notification (if configured)
if [ ! -z "$SLACK_WEBHOOK_URL" ]; then
    log "📱 Sending notification..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ DGTT Auto-École backup completed successfully at $(date)\"}" \
        $SLACK_WEBHOOK_URL 2>/dev/null || warning "Notification failed"
fi

# 10. Final summary
log "📊 Backup Summary"
echo "=================="
echo "Date: $(date)"
echo "Backup Directory: $BACKUP_DIR"
echo "Files Created:"
ls -la $BACKUP_DIR/*_$DATE.* 2>/dev/null || echo "No files found"
echo ""
echo "Total Size:"
du -sh $BACKUP_DIR 2>/dev/null || echo "Unable to calculate size"
echo ""
echo "Next Backup: $(date -d "+1 day" +%Y-%m-%d)"
echo "Cleanup Date: $(date -d "+$RETENTION_DAYS days" +%Y-%m-%d)"

success "🎉 Backup process completed successfully!"

# Exit with success code
exit 0

# Multi-stage build for production-ready Laravel application
FROM php:8.2-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    postgresql-dev \
    nodejs \
    npm \
    supervisor \
    nginx \
    openssl \
    && rm -rf /var/cache/apk/*

# Install PHP extensions with optimizations
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Set working directory
WORKDIR /var/www/html

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies with optimizations
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction \
    && composer dump-autoload --optimize --classmap-authoritative

# Copy application code
COPY . .

# Install and build frontend assets
RUN npm ci --only=production && npm run build && npm cache clean --force

# Production stage
FROM php:8.2-fpm-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    postgresql-client \
    openssl \
    && rm -rf /var/cache/apk/*

# Copy PHP extensions from base stage
COPY --from=base /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=base /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application from base stage
COPY --from=base /var/www/html .

# Create non-root user
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -D -S -G www www

# Set permissions
RUN chown -R www:www /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Create .env file if it doesn't exist
RUN if [ ! -f .env ]; then \
    echo "APP_NAME=DGTT Auto-Ecole\n\
APP_ENV=production\n\
APP_KEY=\n\
APP_DEBUG=false\n\
APP_URL=https://api.dgtt.local\n\
\n\
LOG_CHANNEL=stack\n\
LOG_LEVEL=info\n\
\n\
DB_CONNECTION=pgsql\n\
DB_HOST=postgres-primary\n\
DB_PORT=5432\n\
DB_DATABASE=dgtt_autoecole\n\
DB_USERNAME=dgtt_user\n\
DB_PASSWORD=\n\
\n\
CACHE_DRIVER=redis\n\
SESSION_DRIVER=redis\n\
QUEUE_CONNECTION=rabbitmq\n\
\n\
REDIS_HOST=redis-primary\n\
REDIS_PORT=6379\n\
REDIS_PASSWORD=\n\
\n\
RABBITMQ_HOST=rabbitmq\n\
RABBITMQ_PORT=5672\n\
RABBITMQ_USER=\n\
RABBITMQ_PASSWORD=\n\
\n\
MAIL_MAILER=smtp\n\
MAIL_HOST=smtp.gmail.com\n\
MAIL_PORT=587\n\
MAIL_USERNAME=\n\
MAIL_PASSWORD=\n\
MAIL_ENCRYPTION=tls\n\
MAIL_FROM_ADDRESS=noreply@dgtt.fr\n\
MAIL_FROM_NAME=\"DGTT Auto-Ecole\"" > .env; \
fi

# Generate application key
RUN php artisan key:generate --no-interaction

# Run migrations and optimizations
RUN php artisan migrate --force --no-interaction \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Switch to non-root user
USER www

# Start PHP-FPM
CMD ["php-fpm"]
# Multi-stage build for production-ready Laravel application
FROM php:8.2-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
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
    oniguruma-dev \
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
    opcache \
    xml

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Redis extension (need autoconf and make for PECL)
RUN apk add --no-cache autoconf make && \
    pecl install redis && \
    docker-php-ext-enable redis && \
    apk del autoconf make

# Set working directory
WORKDIR /var/www/html

# Copy composer files (composer.lock is optional)
COPY composer.json ./
COPY composer.lock* ./

# Install PHP dependencies (without scripts since app code isn't copied yet)
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# Copy application code
COPY . .

# Run composer scripts and optimize autoloader after app code is available
RUN composer dump-autoload --optimize --classmap-authoritative

# Install and build frontend assets (if package.json exists)
RUN if [ -f package.json ]; then npm install && npm run build && npm cache clean --force; fi

# Production stage
FROM php:8.2-fpm-alpine AS production

# Install runtime dependencies including PHP extension libraries
RUN apk add --no-cache \
    nginx \
    supervisor \
    postgresql-client \
    openssl \
    curl \
    libpng \
    libjpeg-turbo \
    libzip \
    freetype \
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
    echo 'APP_NAME="DGTT Auto-Ecole"' > .env && \
    echo 'APP_ENV=production' >> .env && \
    echo 'APP_KEY=' >> .env && \
    echo 'APP_DEBUG=false' >> .env && \
    echo 'APP_URL=http://168.119.123.247/api' >> .env && \
    echo '' >> .env && \
    echo 'LOG_CHANNEL=stack' >> .env && \
    echo 'LOG_LEVEL=info' >> .env && \
    echo '' >> .env && \
    echo 'DB_CONNECTION=pgsql' >> .env && \
    echo 'DB_HOST=postgres' >> .env && \
    echo 'DB_PORT=5432' >> .env && \
    echo 'DB_DATABASE=dgtt_auto_ecole' >> .env && \
    echo 'DB_USERNAME=dgtt_user' >> .env && \
    echo 'DB_PASSWORD=dgtt_password_secure_2024' >> .env && \
    echo '' >> .env && \
    echo 'CACHE_DRIVER=redis' >> .env && \
    echo 'SESSION_DRIVER=redis' >> .env && \
    echo 'QUEUE_CONNECTION=rabbitmq' >> .env && \
    echo '' >> .env && \
    echo 'REDIS_HOST=redis' >> .env && \
    echo 'REDIS_PORT=6379' >> .env && \
    echo 'REDIS_PASSWORD=' >> .env && \
    echo '' >> .env && \
    echo 'RABBITMQ_HOST=rabbitmq' >> .env && \
    echo 'RABBITMQ_PORT=5672' >> .env && \
    echo 'RABBITMQ_USER=dgtt_user' >> .env && \
    echo 'RABBITMQ_PASSWORD=dgtt_password_secure_2024' >> .env && \
    echo 'RABBITMQ_VHOST=dgtt_vhost' >> .env && \
    echo '' >> .env && \
    echo 'MAIL_MAILER=smtp' >> .env && \
    echo 'MAIL_HOST=smtp.gmail.com' >> .env && \
    echo 'MAIL_PORT=587' >> .env && \
    echo 'MAIL_USERNAME=' >> .env && \
    echo 'MAIL_PASSWORD=' >> .env && \
    echo 'MAIL_ENCRYPTION=tls' >> .env && \
    echo 'MAIL_FROM_ADDRESS=noreply@dgtt.fr' >> .env && \
    echo 'MAIL_FROM_NAME="DGTT Auto-Ecole"' >> .env; \
fi

# Generate application key
RUN php artisan key:generate --no-interaction

# Run optimizations (migrations will be handled at runtime)
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Create nginx configuration
RUN echo 'server {\n\
    listen 80;\n\
    server_name localhost;\n\
    root /var/www/html/public;\n\
    index index.php index.html;\n\
\n\
    location / {\n\
        try_files $uri $uri/ /index.php?$query_string;\n\
    }\n\
\n\
    location ~ \.php$ {\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_index index.php;\n\
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;\n\
        include fastcgi_params;\n\
    }\n\
\n\
    location /health {\n\
        access_log off;\n\
        return 200 "healthy\\n";\n\
        add_header Content-Type text/plain;\n\
    }\n\
}' > /etc/nginx/http.d/default.conf

# Create supervisor configuration
RUN echo '[supervisord]\n\
nodaemon=true\n\
user=root\n\
\n\
[program:php-fpm]\n\
command=php-fpm -F\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:nginx]\n\
command=nginx -g "daemon off;"\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0' > /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
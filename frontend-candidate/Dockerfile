# Multi-stage build for React Student Frontend
FROM node:18-alpine AS base

WORKDIR /app

# Install dependencies (including dev dependencies for build)
COPY package*.json ./
RUN npm install && npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage with Nginx
FROM nginx:alpine AS production

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache curl

# Copy built assets
COPY --from=base /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Use existing nginx user (already exists in nginx:alpine)
# No need to create user as nginx:alpine already has nginx user

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Run as root for now to avoid permission issues
# USER nginx

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
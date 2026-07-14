# BookStack Deployment Guide

This guide provides instructions for deploying and configuring BookStack for the pCloud documentation infrastructure.

## Overview

BookStack is a simple, self-hosted, platform for organizing and storing information. This setup includes:

- **Primary Domain**: `bookstack.shannonjlove.cloud` 
- **Alias Domain**: `docs.shannonjlove.cloud`
- **API Access**: Token-based authentication for automated imports

## Prerequisites

- Docker and Docker Compose installed
- SSL/TLS certificates for both domains
- Valid domain DNS records pointing to deployment server
- Minimum 2GB RAM, 10GB storage

## Quick Start

### 1. Setup Environment

```bash
# Clone/prepare the repository
cd /path/to/pcloud.github.com

# Copy configuration templates
cp .env.bookstack.example .env.bookstack
cp docker-compose.bookstack.example.yml docker-compose.yml
cp nginx.conf.bookstack.example nginx.conf
```

### 2. Configure Environment Variables

Edit `.env.bookstack` with your settings:

```bash
# Generate a random APP_KEY
# On Linux/Mac:
echo "base64:$(openssl rand -base64 32)"

# Edit the file
nano .env.bookstack

# Set these critical variables:
# - APP_KEY (generated above)
# - APP_URL (https://bookstack.shannonjlove.cloud)
# - DB_PASSWORD (secure password)
# - ADMIN_EMAIL (your email)
# - ADMIN_PASSWORD (secure password)
```

### 3. Setup SSL Certificates

```bash
# Create SSL directory
mkdir -p ssl

# Option A: Use Let's Encrypt with Certbot
certbot certonly --standalone \
  -d bookstack.shannonjlove.cloud \
  -d docs.shannonjlove.cloud

# Option B: Use self-signed certificate (for testing only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/bookstack.key \
  -out ssl/bookstack.crt

# Copy certificates to ssl directory (if using Certbot)
sudo cp /etc/letsencrypt/live/bookstack.shannonjlove.cloud/fullchain.pem ssl/bookstack.crt
sudo cp /etc/letsencrypt/live/bookstack.shannonjlove.cloud/privkey.pem ssl/bookstack.key
```

### 4. Deploy with Docker Compose

```bash
# Source environment variables
export $(cat .env.bookstack | grep -v '#' | xargs)

# Start services
docker-compose up -d

# Check service health
docker-compose ps

# View logs
docker-compose logs -f bookstack
```

### 5. Verify Installation

```bash
# Run verification script
./scripts/verify-bookstack.sh

# Expected output:
# ✓ bookstack.shannonjlove.cloud responds on HTTP
# ✓ docs.shannonjlove.cloud responds on HTTP
# ✓ bookstack.shannonjlove.cloud responds on HTTPS
# ✓ /login endpoint accessible
# ✓ API token authenticated successfully
```

## Post-Installation Setup

### 1. Initial Login

- URL: `https://bookstack.shannonjlove.cloud`
- Email: Use `ADMIN_EMAIL` from `.env.bookstack`
- Password: Use `ADMIN_PASSWORD` from `.env.bookstack`

### 2. Generate API Token

1. Login to BookStack
2. Go to Settings → API Tokens
3. Click "Create Token"
4. Name it "SJL Importer" or similar
5. Copy the **Token ID** and **Token Secret**

### 3. Store API Credentials

Update credentials in password manager:

```
Service: BookStack API
URL: https://bookstack.shannonjlove.cloud
Token ID: [from step above]
Token Secret: [from step above]
```

Also update environment:

```bash
# In .env.bookstack
BOOKSTACK_TOKEN_ID='your-token-id'
BOOKSTACK_TOKEN_SECRET='your-token-secret'
```

### 4. Configure Nginx SSL Renewal

For Let's Encrypt certificates with auto-renewal:

```bash
# Create renewal hook
mkdir -p /etc/letsencrypt/renewal-hooks/post

# Create file: /etc/letsencrypt/renewal-hooks/post/bookstack-reload.sh
#!/bin/bash
docker-compose -f /path/to/docker-compose.yml exec -T nginx nginx -s reload

chmod +x /etc/letsencrypt/renewal-hooks/post/bookstack-reload.sh

# Enable certbot renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

## Verification

Run the verification script at any time:

```bash
./scripts/verify-bookstack.sh

# With API token environment variables set:
export BOOKSTACK_TOKEN_ID='your-token-id'
export BOOKSTACK_TOKEN_SECRET='your-token-secret'
./scripts/verify-bookstack.sh
```

Expected status when fully deployed:

```
✓ bookstack.shannonjlove.cloud responds on HTTP
✓ docs.shannonjlove.cloud responds on HTTP
✓ bookstack.shannonjlove.cloud responds on HTTPS
⚠ docs.shannonjlove.cloud HTTPS has issues (expected for alias)
✓ /api/books endpoint accessible
✓ /login endpoint accessible
✓ API token authenticated successfully
```

## API Usage Examples

### List Books

```bash
curl -H "Authorization: Token $BOOKSTACK_TOKEN_ID:$BOOKSTACK_TOKEN_SECRET" \
  https://bookstack.shannonjlove.cloud/api/books
```

### Create Book

```bash
curl -X POST \
  -H "Authorization: Token $BOOKSTACK_TOKEN_ID:$BOOKSTACK_TOKEN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "SDK Documentation",
    "description": "PCloud SDK Documentation"
  }' \
  https://bookstack.shannonjlove.cloud/api/books
```

### Upload Page

```bash
curl -X POST \
  -H "Authorization: Token $BOOKSTACK_TOKEN_ID:$BOOKSTACK_TOKEN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": 1,
    "chapter_id": null,
    "name": "Getting Started",
    "html": "<h1>Getting Started with SDK</h1><p>Content here...</p>"
  }' \
  https://bookstack.shannonjlove.cloud/api/pages
```

See [BookStack API Documentation](https://demo.bookstackapp.com/api/docs) for full reference.

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs mysql
docker-compose logs bookstack

# Common issues:
# - Port 3306 already in use: Change DB_PORT in docker-compose.yml
# - SSL certificate missing: Copy certificates to ./ssl directory
# - Permission issues: Run with sudo or check file permissions
```

### HTTPS Certificate Issues

```bash
# Verify certificate
openssl x509 -in ssl/bookstack.crt -text -noout

# Check certificate chain
openssl s_client -connect bookstack.shannonjlove.cloud:443

# Regenerate self-signed (testing only)
rm ssl/bookstack.*
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/bookstack.key -out ssl/bookstack.crt
```

### API Token Not Working

```bash
# Verify token format (should be ID:SECRET)
echo "Token: $BOOKSTACK_TOKEN_ID:$BOOKSTACK_TOKEN_SECRET"

# Test API access
curl -v -H "Authorization: Token $BOOKSTACK_TOKEN_ID:$BOOKSTACK_TOKEN_SECRET" \
  https://bookstack.shannonjlove.cloud/api/books

# Check response for 401 (unauthorized) or 404 (endpoint not found)
# 401 = invalid token
# 404 = BookStack not deployed
```

### Database Connection Failed

```bash
# Verify MySQL is running
docker-compose ps mysql

# Check MySQL logs
docker-compose logs mysql

# Verify credentials match between services
grep DB_ .env.bookstack
docker-compose logs bookstack | grep -i database
```

## Maintenance

### Regular Backups

```bash
# Backup database
docker-compose exec mysql mysqldump -u bookstack -p$DB_PASSWORD bookstack > backup.sql

# Backup volumes
docker run --rm -v bookstack_uploads:/source -v $(pwd):/backup \
  alpine tar czf /backup/uploads-backup.tar.gz -C /source .
```

### Updates

```bash
# Stop services
docker-compose down

# Pull latest images
docker-compose pull

# Start updated services
docker-compose up -d

# Verify
./scripts/verify-bookstack.sh
```

## Security Notes

1. **Always use HTTPS** in production
2. **Regenerate APP_KEY** before going live
3. **Use strong passwords** for all accounts
4. **Rotate API tokens** periodically
5. **Enable 2FA** for admin accounts
6. **Keep backups** in secure location
7. **Review access logs** regularly

## Support & Documentation

- [BookStack Official Documentation](https://www.bookstackapp.com/)
- [BookStack API Reference](https://demo.bookstackapp.com/api/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)

## Related Files

- `.env.bookstack.example` - Environment configuration template
- `docker-compose.bookstack.example.yml` - Docker services definition
- `nginx.conf.bookstack.example` - Nginx reverse proxy configuration
- `scripts/verify-bookstack.sh` - Verification and testing script
- `CLAUDE.md` - Repository documentation

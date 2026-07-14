# Wiki.js Setup Guide

This document provides instructions for setting up and running Wiki.js for the wiki.shannonjlove.cloud subdomain.

## Prerequisites

- Docker and Docker Compose installed
- Domain: `shannonjlove.cloud` configured with your DNS provider
- Access to your hosting/server where this will be deployed
- SSL certificates (we'll use Let's Encrypt with Certbot)

## Quick Start

### 1. Simple Setup (Local Testing or Behind Load Balancer)

If you just want to run wiki.js without the nginx reverse proxy:

```bash
docker-compose up -d wiki
```

This will start wiki.js on `http://localhost:3000`

Access the wiki at: `http://localhost:3000`

### 2. Full Setup with Nginx Reverse Proxy

For production with SSL and subdomain routing:

#### Step 1: Set up SSL Certificates

First, obtain SSL certificates from Let's Encrypt:

```bash
# Install certbot if you haven't already
apt-get install certbot python3-certbot-dns-cloudflare  # or appropriate DNS plugin

# Create ssl directory
mkdir -p ssl

# Obtain certificate (replace with your DNS provider method)
certbot certonly --standalone -d wiki.shannonjlove.cloud
```

Then copy the certificates to the ssl directory:

```bash
sudo cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/*
```

#### Step 2: Configure DNS

Add a DNS record in your DNS provider (CloudFlare, GoDaddy, etc.). Choose one of the following:

**Option A: Using an A record (direct IP)**
| Type | Name | Content |
|------|------|---------|
| A | wiki | Your server IP address |

**Option B: Using a CNAME record (delegation)**
| Type | Name | Content |
|------|------|---------|
| CNAME | wiki | your-domain.com |

Note: You can only use one type of record per subdomain. Use an A record if pointing to a server IP, or a CNAME record if delegating to another domain.

#### Step 3: Start Services with Nginx

Uncomment the nginx service in `docker-compose.yml` or use this command:

```bash
docker-compose up -d
```

This will start both wiki.js and nginx.

#### Step 4: Set Up SSL Certificate Auto-Renewal

```bash
# Create renewal script
cat > renew-ssl.sh << 'EOF'
#!/bin/bash
certbot renew --quiet
cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/privkey.pem ssl/key.pem
docker-compose exec nginx nginx -s reload
EOF

chmod +x renew-ssl.sh

# Add to crontab to run monthly
(crontab -l 2>/dev/null; echo "0 2 1 * * /path/to/renew-ssl.sh") | crontab -
```

## Accessing Wiki.js

### First Time Setup

1. Navigate to your wiki URL:
   - Local: `http://localhost:3000`
   - Production: `https://wiki.shannonjlove.cloud`

2. Complete the setup wizard:
   - Choose SQLite (already configured)
   - Set up your admin user
   - Configure site settings

### Admin Panel

Once logged in, access the admin panel to:
- Manage users and permissions
- Configure wiki settings
- Manage navigation
- Set up storage options

## Database

The SQLite database is stored in a Docker volume (`wiki_data`). This persists data across container restarts.

To back up your database:

```bash
docker run --rm -v wiki_data:/data -v $(pwd):/backup \
  busybox cp /data/wiki.sqlite /backup/wiki.sqlite.backup
```

## Common Tasks

### Restart Services

```bash
docker-compose restart
```

### Stop Services

```bash
docker-compose down
```

### View Logs

```bash
docker-compose logs -f wiki
```

### Update Wiki.js

```bash
docker-compose pull wiki
docker-compose up -d
```

## Troubleshooting

### Certificate Issues

If nginx fails to start with certificate errors:

```bash
# Verify certificate paths exist
ls -la ssl/

# Verify certificate is valid
openssl x509 -in ssl/cert.pem -text -noout
```

### Port Already in Use

If port 3000 or 80/443 is already in use:

```bash
# Change port in docker-compose.yml
# Change "3000:3000" to "3001:3000" for wiki
# Change "80:80" to "8080:80" for nginx
```

### Wiki Not Responding

Check service health:

```bash
docker-compose ps
docker-compose logs wiki
```

## Production Recommendations

1. **Use a managed database** (PostgreSQL) instead of SQLite for better performance
2. **Enable backups** of the wiki database regularly
3. **Use Cloudflare or similar** for DDoS protection and performance
4. **Monitor logs** and set up alerting
5. **Keep Docker images updated** regularly
6. **Use strong admin passwords** and enable 2FA
7. **Configure backup locations** in Wiki.js admin panel

## Updating docker-compose.yml for Production

For production with PostgreSQL:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: wiki
      POSTGRES_USER: wiki
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - wiki-network

  wiki:
    image: requarks/wiki:latest
    environment:
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: wiki
      DB_PASS: ${DB_PASSWORD}
      DB_NAME: wiki
    depends_on:
      - postgres
    networks:
      - wiki-network
    # ... rest of config

volumes:
  postgres_data:
```

Create a `.env` file with your database password:

```
DB_PASSWORD=your_secure_password_here
```

## Support

For more information on Wiki.js:
- [Official Documentation](https://docs.requarks.io/wiki.js)
- [GitHub Repository](https://github.com/Requarks/wiki)

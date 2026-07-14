# pCloud SDK Documentation Site

This is a Jekyll-based documentation site for pCloud SDKs.

## BookStack Integration

### Status
BookStack instances are configured for documentation purposes but currently **not fully deployed**.

### Domains
- **bookstack.shannonjlove.cloud** - Primary BookStack instance
- **docs.shannonjlove.cloud** - Documentation alias

### Current Verification Results

#### HTTP Connectivity
- ✅ Both domains are reachable over HTTP (port 80)
- ⚠️ Both return generic nginx/openresty default page on root path
- ❌ No BookStack endpoints responding (404 on /api, /login, etc.)

#### HTTPS Connectivity  
- ❌ TLS handshake failures on both domains
  - bookstack.shannonjlove.cloud: "unrecognized name" error (SNI issue)
  - docs.shannonjlove.cloud: Connection reset by peer

### API Credentials
Configured but **not yet functional**:
```
BOOKSTACK_URL='https://bookstack.shannonjlove.cloud'
BOOKSTACK_TOKEN_ID='0GfibwREHLX4Li8eXoPrARcIkZJjs9n1'
BOOKSTACK_TOKEN_SECRET='5UCfFgn4GlRIIl65VaGUF6Nr8i6s4JRi'
```

### Setup Requirements

To make BookStack fully operational, the following steps are needed:

1. **Deploy BookStack application**
   - Install BookStack on the server hosting bookstack.shannonjlove.cloud
   - Use Docker, direct installation, or container orchestration
   - Ensure application is accessible at root path

2. **Configure HTTPS/SSL Certificates**
   - Obtain valid SSL certificates for both domains
   - Fix SNI configuration on the load balancer/reverse proxy
   - Ensure proper certificate chain setup

3. **Network Configuration**
   - Update reverse proxy/nginx configuration to route requests to BookStack
   - Configure proper upstream backend for both domains
   - Enable gzip and other performance optimizations

4. **Database Setup**
   - Configure MariaDB/MySQL backend
   - Set database credentials in BookStack environment
   - Run migrations if needed

5. **Environment Configuration**
   - Set APP_KEY and other required environment variables
   - Configure authentication settings
   - Enable API token support

### Testing

To verify full deployment, run:
```bash
./scripts/verify-bookstack.sh
```

Or manually test:
```bash
# HTTP root path
curl http://bookstack.shannonjlove.cloud/ | grep -i bookstack

# HTTPS with valid certificate
curl https://bookstack.shannonjlove.cloud/ 

# API endpoint
curl -H "Authorization: Token TOKEN_ID:TOKEN_SECRET" \
  https://bookstack.shannonjlove.cloud/api/books
```

### Related Documentation
- [BookStack Official Docs](https://www.bookstackapp.com/)
- [BookStack API Documentation](https://demo.bookstackapp.com/api/docs)

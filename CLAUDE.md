# pCloud SDK Documentation Site

This is a Jekyll-based documentation site for pCloud SDKs.

## BookStack Integration

### Status
BookStack **was fully deployed and operational** as of 2026-07-11, but is currently **offline/inaccessible** as of 2026-07-14.

**Action Required:** Services need to be restarted or proxy configuration needs to be restored.

### Domains & Access
- **Public Documentation:** `https://docs.shannonjlove.cloud` (via Nginx Proxy Manager)
- **Admin Panel:** `http://100.115.66.75` (via Tailscale VPN only)
- **Server SSH:** `ssh root@100.115.66.75` (via Tailscale)

### Current Verification Results (2026-07-14)

#### HTTP Connectivity
- ✅ Both domains are reachable over HTTP (port 80)
- ⚠️ Both return nginx default page instead of BookStack
- ❌ BookStack endpoints not responding (404 from nginx, not BookStack app)

#### HTTPS Connectivity  
- ❌ TLS handshake failures (certificate/SNI issues)
  - bookstack.shannonjlove.cloud: "unrecognized name" error
  - docs.shannonjlove.cloud: Connection reset by peer

#### Previous Status (2026-07-11) - Was Working
- ✅ BookStack service running and healthy
- ✅ Database connected with 120+ migrations complete
- ✅ Health check returning: `{"database":true,"cache":true,"session":true}`
- ✅ Public HTTP access working: `http://docs.shannonjlove.cloud`
- ✅ Tailscale admin access working: `http://100.115.66.75`
- ⏳ HTTPS needed Let's Encrypt certificate

### API Credentials (Available)
```
BOOKSTACK_URL='https://bookstack.shannonjlove.cloud'
BOOKSTACK_TOKEN_ID='0GfibwREHLX4Li8eXoPrARcIkZJjs9n1'
BOOKSTACK_TOKEN_SECRET='5UCfFgn4GlRIIl65VaGUF6Nr8i6s4JRi'
```

### Current Deployment

**Infrastructure:**
- **Container Runtime:** Podman (systemd Quadlet services)
- **Reverse Proxy:** Nginx Proxy Manager (NPM container)
- **Application:** BookStack (docker.io/linuxserver/bookstack:latest)
- **Database:** MariaDB (in Podman container)
- **Networks:** infra.network, bookstack.network

**Service Configuration Files:**
- `/etc/bookstack/bookstack.env` - Environment variables
- `/etc/containers/systemd/bookstack.container` - BookStack service
- `/etc/containers/systemd/bookstack-db.container` - Database service
- `/data/nginx/proxy_host/bookstack.conf` - Nginx reverse proxy (in NPM)

### Troubleshooting Required

**Step 1: Check Service Status**
```bash
ssh root@100.115.66.75
systemctl status bookstack.service
systemctl status bookstack-db.service
```

**Step 2: Restart if Needed**
```bash
# Restart in order: DB first, then app
systemctl restart bookstack-db.service
sleep 10
systemctl restart bookstack.service
```

**Step 3: Verify Health**
```bash
curl http://127.0.0.1:80/status
# Should return: {"database":true,"cache":true,"session":true}
```

**Step 4: Test Public Access**
```bash
curl http://docs.shannonjlove.cloud
# Should return BookStack homepage
```

### Documentation

For complete setup information and troubleshooting:
- **`BOOKSTACK_CURRENT_STATUS.md`** - Current issue diagnosis and restart procedures
- **`BOOKSTACK_DEPLOYMENT.md`** - Original deployment guide
- **`BookStack_Complete_Configuration_Guide.md`** - Full infrastructure details
- **`BookStack_Quick_Reference.md`** - Command reference and common tasks

### Related Documentation
- [BookStack Official Docs](https://www.bookstackapp.com/)
- [BookStack API Documentation](https://demo.bookstackapp.com/api/docs)
- [Nginx Proxy Manager Docs](https://nginxproxymanager.com/)
- [Tailscale VPN](https://tailscale.com/)

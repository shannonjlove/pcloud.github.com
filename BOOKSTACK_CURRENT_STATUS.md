# BookStack Access Configuration - Current Status

**Last Verified:** 2026-07-14  
**Status:** ⚠️ **Service offline or misconfigured** (Previously production-ready as of 2026-07-11)

---

## Critical Finding

Based on verification performed on 2026-07-14, the BookStack service is **currently not responding** despite being fully configured and deployed as of 2026-07-11.

| Component | Previous Status (2026-07-11) | Current Status (2026-07-14) | Action Required |
|-----------|------------------------------|----------------------------|-----------------|
| **BookStack Service** | ✅ Running | ❌ Not responding | Restart service |
| **Public Access** | ✅ http://docs.shannonjlove.cloud | ❌ Returns nginx default page | Check proxy routing |
| **Database** | ✅ Connected, healthy | ❓ Unknown | Verify connectivity |
| **HTTPS** | ⏳ Self-signed ready | ❌ TLS handshake fails | Check certificate |
| **Tailscale Access** | ✅ http://100.115.66.75 | ❓ Unknown | Test via VPN |

---

## What Changed?

**Previously Working (2026-07-11):**
```bash
✓ Health check: {"database":true,"cache":true,"session":true}
✓ Public access: http://docs.shannonjlove.cloud → BookStack homepage
✓ All 120+ database migrations complete
✓ Systemd services: bookstack.service, bookstack-db.service running
```

**Currently Observed (2026-07-14):**
```bash
✗ Health check: 404 Not Found (nginx default page)
✗ Public access: http://docs.shannonjlove.cloud returns nginx default page
✗ API endpoints: All return 404 from nginx, not BookStack
✗ Services: Unknown (needs verification)
```

---

## Immediate Troubleshooting Steps

### Step 1: Check Service Status

SSH to the server and verify services:

```bash
ssh root@100.115.66.75

# Check BookStack service
systemctl status bookstack.service

# Check database service  
systemctl status bookstack-db.service

# Check Nginx Proxy Manager
podman ps | grep -E "bookstack|npm|proxy"
```

**Expected Output:**
```
bookstack.service - BookStack knowledge base
   Loaded: loaded (...)
   Active: active (running) ← Should show this
   
bookstack-db.service - BookStack Database
   Loaded: loaded (...)
   Active: active (running) ← Should show this
```

### Step 2: Verify Service Health

```bash
# Check BookStack health endpoint
curl -s http://127.0.0.1:80/status | jq .

# Expected response:
# {"database":true,"cache":true,"session":true}
```

### Step 3: Check Proxy Configuration

```bash
# List proxy hosts in NPM
podman exec nginx-proxy-manager ls -la /data/nginx/proxy_host/

# Test proxy connectivity
podman exec nginx-proxy-manager curl -v http://bookstack:80

# Check nginx config syntax
podman exec nginx-proxy-manager nginx -t

# View nginx error logs
podman logs nginx-proxy-manager | tail -50
```

### Step 4: Restart Services (if needed)

```bash
# If services are stopped, restart them in order:
systemctl start bookstack-db.service
sleep 10
systemctl start bookstack.service

# Wait 30 seconds for migrations
sleep 30

# Verify health
curl http://127.0.0.1:80/status
```

---

## Original Configuration Reference

### Environment Variables
**Location:** `/etc/bookstack/bookstack.env`

```bash
# Database
DB_HOST=bookstack-db
DB_DATABASE=bookstack
DB_USERNAME=bookstack
DB_PASSWORD=[SECURE_PASSWORD]

# Application
APP_URL=https://docs.shannonjlove.cloud
APP_PROXIES=*
APP_KEY=base64:RmUBCHWMmvO9s88Zc5nsoAz6n6wJMft5rruPsq1Jssw=

# System
PUID=1000
PGID=1000
TZ=America/Chicago
```

### Service Definition
**Location:** `/etc/containers/systemd/bookstack.container`

```
[Unit]
Description=BookStack knowledge base
After=network-online.target infra-network.service bookstack-network.service
After=bookstack-db.service
Requires=bookstack-db.service infra-network.service bookstack-network.service

[Container]
Image=docker.io/linuxserver/bookstack:latest
ContainerName=bookstack
Network=infra.network
Network=bookstack.network
Volume=bookstack-data.volume:/config:Z
EnvironmentFile=/etc/bookstack/bookstack.env
HealthCmd=curl -sf http://localhost:80/status || exit 1
HealthInterval=30s
HealthRetries=3
HealthTimeout=10s

[Service]
Restart=always
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target default.target
```

### Nginx Proxy Host
**Location:** `/data/nginx/proxy_host/bookstack.conf` (inside NPM container)

```nginx
upstream bookstack {
  server bookstack:80;
  keepalive 32;
}

# HTTP Redirect
server {
  listen 80;
  listen [::]:80;
  server_name docs.shannonjlove.cloud;
  location / {
    return 301 https://$server_name$request_uri;
  }
}

# HTTPS
server {
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name docs.shannonjlove.cloud;

  ssl_certificate /data/letsencrypt/live/docs.shannonjlove.cloud/fullchain.pem;
  ssl_certificate_key /data/letsencrypt/live/docs.shannonjlove.cloud/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;

  location / {
    proxy_pass http://bookstack;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header Connection "";
  }
}
```

---

## Common Issues & Solutions

### Issue 1: "Connection refused" on health check

**Symptoms:** `curl http://127.0.0.1:80/status` returns connection error

**Cause:** BookStack service not running

**Solution:**
```bash
# Check if stopped
systemctl status bookstack.service

# If stopped, start it
systemctl start bookstack.service

# Wait for startup
sleep 30

# Verify
curl http://127.0.0.1:80/status
```

### Issue 2: Nginx can't reach BookStack

**Symptoms:** Proxy returns 502 Bad Gateway

**Cause:** Network connectivity issue or service down

**Solution:**
```bash
# Test from NPM container
podman exec nginx-proxy-manager curl -v http://bookstack:80

# Verify networks
podman network inspect infra
podman network inspect bookstack

# Check BookStack service
systemctl status bookstack.service
podman logs bookstack
```

### Issue 3: HTTPS certificate errors

**Symptoms:** `curl https://docs.shannonjlove.cloud` returns TLS error

**Cause:** Self-signed cert or Let's Encrypt cert not generated

**Solution:**
```bash
# Check certificate
openssl x509 -in /data/letsencrypt/live/docs.shannonjlove.cloud/fullchain.pem -text

# Generate Let's Encrypt cert via NPM
podman exec nginx-proxy-manager certbot certonly --standalone \
  -d docs.shannonjlove.cloud --email admin@shannonjlove.cloud

# Reload nginx
podman exec nginx-proxy-manager nginx -s reload
```

### Issue 4: Database connection failed

**Symptoms:** BookStack returns "database connection error"

**Cause:** Database service down or credentials wrong

**Solution:**
```bash
# Check database service
systemctl status bookstack-db.service

# Test database connectivity
podman exec bookstack-db mysql -u bookstack -p -h bookstack-db -e "SELECT 1"

# View database logs
journalctl -u bookstack-db.service -n 50
```

---

## Access Points (After Restart)

### Public Documentation
```bash
# HTTP (redirects to HTTPS)
curl http://docs.shannonjlove.cloud

# HTTPS (once cert is valid)
curl https://docs.shannonjlove.cloud
```

### Admin Panel (Tailscale-only)
```bash
# Via Tailscale VPN
http://100.115.66.75

# SSH Access
ssh root@100.115.66.75
```

### Verification Endpoints
```bash
# Local health check (run on server)
curl http://127.0.0.1:80/status

# Database status
curl http://127.0.0.1:80/status | jq '.database'

# From external (after proxy fixed)
curl -I http://docs.shannonjlove.cloud
```

---

## Complete Restart Procedure

If services need to be fully restarted:

```bash
ssh root@100.115.66.75

# 1. Stop services in reverse order
systemctl stop bookstack.service
systemctl stop bookstack-db.service

# 2. Wait for clean shutdown
sleep 5

# 3. Start services in correct order
systemctl start bookstack-db.service
sleep 10
systemctl start bookstack.service

# 4. Wait for initialization
sleep 30

# 5. Verify health
curl http://127.0.0.1:80/status

# 6. Check proxy
podman exec nginx-proxy-manager curl http://bookstack:80
```

---

## File Locations Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| **Environment** | `/etc/bookstack/bookstack.env` | BookStack config vars |
| **Service** | `/etc/containers/systemd/bookstack.container` | Systemd service definition |
| **Database Service** | `/etc/containers/systemd/bookstack-db.container` | Database service definition |
| **Nginx Config** | `/data/nginx/proxy_host/bookstack.conf` | Reverse proxy (in NPM) |
| **SSL Certs** | `/data/letsencrypt/live/docs.shannonjlove.cloud/` | Certificates (in NPM) |
| **Data Volume** | `bookstack-data.volume` | Persistent storage |
| **Tailscale** | `100.115.66.75` | VPN access IP |

---

## Next Steps

1. **SSH to server:** `ssh root@100.115.66.75`
2. **Run status checks:** See "Immediate Troubleshooting Steps" above
3. **Restart if needed:** Follow "Complete Restart Procedure"
4. **Verify access:** Test public URL and Tailscale VPN access
5. **Check HTTPS:** Ensure Let's Encrypt cert is valid
6. **Review logs:** Check for any errors in services

---

## Related Documentation

- **Setup Guide:** See `BOOKSTACK_DEPLOYMENT.md` for original deployment steps
- **Quick Reference:** See `BookStack_Quick_Reference.md` for command reference
- **Configuration Details:** See `BookStack_Complete_Configuration_Guide.md` for full setup

---

**Status Last Updated:** 2026-07-14 03:45 UTC  
**Service Status:** Requires investigation and likely restart  
**Support:** Contact server admin at `root@100.115.66.75`

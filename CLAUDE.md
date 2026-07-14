# CLAUDE.md - Wiki.js & Templates Deployment Guide

This file documents the wiki.js deployment, helper scripts, and service documentation template system for Claude Code and other AI agents.

## 🎯 Quick Deploy (Via Claude)

Request Claude to deploy with:
```
Deploy wiki.js to wiki.shannonjlove.cloud using SSH/Tailscale.
Provide: server access details, username, auth method, server IP.
```

Claude will:
- SSH/Tailscale into your server
- Start docker-compose with wiki.js
- Get SSL certificate
- Upload templates
- Verify deployment

---

## 📋 Codebase Summary

### What This Project Contains

**Wiki.js Installation**:
- `docker-compose.yml` - Wiki.js + SQLite + volumes
- `nginx.conf` - Reverse proxy with SSL/TLS
- `WIKI_SETUP.md` - Complete setup guide
- Helper scripts: `wiki-start.sh`, `wiki-status.sh`

**Service Documentation Templates**:
- `wiki-templates/service-handoff-template.md` - 20+ section template
- `wiki-templates/TEMPLATE_USAGE_GUIDE.md` - How-to guide
- `wiki-templates/bookstack-example-completed.md` - Real-world example
- `wiki-templates/README.md` - Templates overview

**Upload Tools**:
- `upload-templates-to-wiki.py` - Python automation
- `upload-templates-to-wiki.sh` - Bash helper
- `wiki-templates/create-pages.sh` - GraphQL API uploader
- `GET_AUTH_TOKEN.md` - Token retrieval guide

**Documentation**:
- `COMPLETE_HANDOFF.md` - 1175-line comprehensive handoff
- `DEPLOYMENT_NOTES.md` - Podman Quadlet recommendations
- `UPLOAD_TEMPLATES.md` - Upload instructions

---

## 🚀 Deployment via SSH/Tailscale

### Requirements

- Docker and Docker Compose installed on target server
- SSH access OR Tailscale network access
- Domain: `wiki.shannonjlove.cloud`
- Server IP for DNS A record

### Claude Deployment Request

To have Claude deploy this, provide:

```
Access Method: SSH to example.com port 22
Username: deploy
Auth: [SSH key or password]
Repo Path: /opt/pcloud.github.com
Server IP: 203.0.113.42
```

Claude will then:

1. **Connect to server**
   ```bash
   ssh deploy@example.com
   # or
   ssh deploy@myserver.tailnet-xxxx.ts.net
   ```

2. **Clone/Update repo**
   ```bash
   cd /opt/pcloud.github.com
   git fetch origin
   git checkout claude/wiki-js-subdomain-setup-6d8p7v
   ```

3. **Start wiki.js**
   ```bash
   docker-compose up -d wiki
   sleep 40
   ```

4. **Get SSL certificate**
   ```bash
   certbot certonly --standalone -d wiki.shannonjlove.cloud
   mkdir -p ssl
   sudo cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/fullchain.pem ssl/cert.pem
   sudo cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/privkey.pem ssl/key.pem
   ```

5. **Start full stack**
   ```bash
   docker-compose up -d
   ```

6. **Get auth token** (manual browser step)
   - Visit: http://localhost:3000
   - Complete setup wizard
   - Get JWT token from F12 cookies

7. **Upload templates**
   ```bash
   cd wiki-templates
   ./create-pages.sh https://wiki.shannonjlove.cloud $JWT_TOKEN
   ```

8. **Verify deployment**
   ```bash
   curl https://wiki.shannonjlove.cloud/services/templates
   ```

---

## 🛠️ Local Development

### Quick Start

```bash
# Start wiki.js locally
docker-compose up -d wiki

# View logs
docker-compose logs -f wiki

# Access at http://localhost:3000
```

### Helper Scripts

```bash
# Interactive startup
bash wiki-start.sh

# Health check
bash wiki-status.sh

# Upload templates (requires token)
cd wiki-templates
./create-pages.sh http://localhost:3000 $TOKEN
```

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Wiki.js deployment config |
| `nginx.conf` | Reverse proxy + SSL |
| `wiki-start.sh` | Interactive setup script |
| `wiki-status.sh` | Health check script |
| `COMPLETE_HANDOFF.md` | 1175-line comprehensive guide |
| `wiki-templates/` | 4 documentation templates |
| `upload-templates-to-wiki.py` | Python uploader |
| `GET_AUTH_TOKEN.md` | Token retrieval (3 methods) |

---

## 🔒 Security Notes

- SSL/TLS with modern ciphers (TLS 1.2+)
- Health checks enabled
- Database isolation documented
- Secrets not stored in git
- Backup procedures included
- Tailscale/VPN recommended for admin access

---

## 📊 Deployment Checklist

- [ ] Docker/Docker Compose installed
- [ ] Repository cloned/updated
- [ ] SSL certificate obtained
- [ ] DNS A record configured
- [ ] docker-compose up -d (all services)
- [ ] Wiki.js initial setup completed
- [ ] Auth token obtained
- [ ] Templates uploaded
- [ ] https://wiki.shannonjlove.cloud/services/templates accessible

---

## 🔄 CI/CD & Deployment Hooks

### Pre-deployment Checks

```bash
# Verify docker-compose syntax
docker-compose config

# Check SSL certificates
openssl x509 -in ssl/cert.pem -text -noout

# Verify health endpoints
curl http://localhost:3000/healthz
```

### Post-deployment Verification

```bash
# Check services running
docker-compose ps

# Verify HTTPS
curl -I https://wiki.shannonjlove.cloud

# Test templates page
curl https://wiki.shannonjlove.cloud/services/templates
```

---

## 🎯 Common Tasks

### Deploy Wiki.js

To Claude:
```
Deploy wiki.js to wiki.shannonjlove.cloud
Provide SSH/Tailscale access details
```

### Upload Templates

```bash
cd wiki-templates
./create-pages.sh https://wiki.shannonjlove.cloud $TOKEN
```

### Check Status

```bash
docker-compose ps
docker-compose logs -f wiki
curl https://wiki.shannonjlove.cloud/healthz
```

### Backup

```bash
docker exec wiki-db mysqldump -u wiki -p > backup.sql
docker run --rm -v wiki_data:/data -v $(pwd):/backup \
  busybox tar czf /backup/wiki-data.tar.gz -C /data .
```

### Renew SSL

```bash
certbot renew --quiet
cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/privkey.pem ssl/key.pem
docker-compose exec nginx nginx -s reload
```

---

## 📚 Documentation

- **COMPLETE_HANDOFF.md** - Full reference (start here)
- **WIKI_SETUP.md** - Detailed setup instructions
- **GET_AUTH_TOKEN.md** - Token retrieval methods
- **UPLOAD_TEMPLATES.md** - Upload guide
- **wiki-templates/README.md** - Template learning path

---

## 🔧 Troubleshooting

**Wiki.js won't start**
```bash
docker-compose logs wiki
# Check port 3000 available, disk space, docker running
```

**HTTPS not working**
```bash
ls -la ssl/cert.pem ssl/key.pem
# Check certificates exist and are readable
```

**Templates won't upload**
```bash
# Get fresh token from browser (F12 → Cookies → jwt)
export WIKI_TOKEN="new-token"
./create-pages.sh https://wiki.shannonjlove.cloud $WIKI_TOKEN
```

**DNS not resolving**
```bash
nslookup wiki.shannonjlove.cloud
# Wait 5-15 minutes after adding DNS record
```

---

## 📞 Support

- See `COMPLETE_HANDOFF.md` for comprehensive reference
- See `GET_AUTH_TOKEN.md` for authentication help
- See `UPLOAD_TEMPLATES.md` for upload troubleshooting
- Check logs: `docker-compose logs wiki`
- Test health: `curl https://wiki.shannonjlove.cloud/healthz`

---

## 🎓 Learning Path

1. Read: `COMPLETE_HANDOFF.md` (comprehensive overview)
2. Setup: Follow deployment steps above
3. Verify: Access https://wiki.shannonjlove.cloud
4. Upload: Use template upload scripts
5. Learn: Read `wiki-templates/README.md` for template usage

---

## 📋 Git Branch Info

- **Branch**: `claude/wiki-js-subdomain-setup-6d8p7v`
- **PR**: #1 (Production-ready, code-reviewed)
- **Status**: ✅ Ready to deploy

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07-14 | Initial wiki.js + templates setup |

---

**Last Updated**: 2026-07-14  
**Status**: ✅ Production Ready  
**For Claude Deployment**: Provide SSH/Tailscale access details

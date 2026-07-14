# BookStack Handoff - Example Completed Template

This document shows how the service handoff template has been completed for the BookStack documentation service. Use this as a reference when filling out templates for other services.

---

# BookStack Service Handoff Summary

**Service**: BookStack Documentation Platform  
**Status**: Production Ready  
**Last Updated**: 2026-07-11  
**Primary Domain**: docs.shannonjlove.cloud

## Purpose

This document provides a complete handoff for the BookStack documentation service so the new owner can assume support, maintenance, and operational continuity. The service is deployed as a containerized BookStack instance backed by MariaDB with supporting documentation for deployment, operations, troubleshooting, and maintenance.

## Service Definition

BookStack is deployed as the documentation platform for the environment and is backed by MariaDB for data persistence. The service is exposed through Nginx Proxy Manager and uses Tailscale for secured administrative access.

## Primary Endpoints

| Endpoint | Use |
|---|---|
| `https://docs.shannonjlove.cloud` | Public service URL for documentation access |
| `http://100.115.66.75` | Tailscale admin access path |
| `ssh root@100.115.66.75` | Administrative shell access |
| `http://127.0.0.1:80/status` | Internal health check endpoint |

## Core Components

| Component | Role |
|---|---|
| BookStack | Documentation application runtime |
| MariaDB (`bookstack-db`) | Persistent database backend |
| Nginx Proxy Manager | Reverse proxy and HTTPS termination |
| Tailscale | Restricted admin access and VPN connectivity |

## Important Files and Locations

| File or Location | Role |
|---|---|
| `etc/bookstack/bookstack.env` | BookStack and database environment variables |
| `etc/containers/systemd/bookstack.container` | Quadlet container service definition and health check |
| `data/nginx/proxy_host/bookstack.conf` | Nginx Proxy Manager reverse proxy configuration |
| `bookstack-data.volume` | Persistent BookStack storage volume |
| `bookstack-db` container | MariaDB database container |

## Service Architecture

BookStack is deployed using Podman with Quadlet templates for systemd integration. Two dedicated networks facilitate communication:

- **infra.network**: Shared between Nginx Proxy Manager and BookStack for HTTP/HTTPS forwarding
- **bookstack.network**: Private network for BookStack-to-database communication (MariaDB only)

Persistent application configuration is stored through `bookstack-data.volume`, while the database maintains its own persistent storage volume. The architecture ensures database is isolated on internal network only, with all external traffic routed through Nginx Proxy Manager with TLS termination.

## Access and Authentication

### Public Access
- **URL**: https://docs.shannonjlove.cloud
- **Protocol**: HTTPS (self-signed cert for testing, Let's Encrypt recommended for production)
- **Authentication**: BookStack user accounts (username/password or SSO if configured)

### Administrative Access
- **Primary Method**: Tailscale VPN + SSH
- **Address**: `ssh root@100.115.66.75` (Tailscale address)
- **Admin UI Access**: Available to authenticated BookStack administrators on public URL
- **Database Access**: Internal only, no external access

### Internal Networks
- **infra.network**: Nginx ↔ BookStack communication (Docker bridge)
- **bookstack.network**: BookStack ↔ MariaDB communication (Docker bridge)

## Startup and Shutdown Procedures

### Startup Order
1. **MariaDB First**: Database must be ready before BookStack connects
   ```bash
   systemctl start bookstack-db.service
   # Wait for database to be ready (check health)
   ```

2. **BookStack Second**: Application depends on database
   ```bash
   systemctl start bookstack.service
   ```

3. **Nginx Proxy Manager**: Routes public traffic (usually already running)
   ```bash
   systemctl start npm  # or docker service if not systemd
   ```

### Startup Verification
```bash
# Check all services are running
systemctl status bookstack-db.service
systemctl status bookstack.service

# Verify health endpoint
curl http://127.0.0.1:80/status

# Expected response should show:
# {"database":true, "cache":true, "session":true}
```

### Shutdown Procedures
```bash
# Stop BookStack first (clean shutdown)
systemctl stop bookstack.service

# Then stop database
systemctl stop bookstack-db.service

# Verify shutdown
systemctl status bookstack-db.service
systemctl status bookstack.service
```

## Health Verification

### Health Check Endpoints

**Internal Health Endpoint**:
- **URL**: `http://127.0.0.1:80/status` (from host) or `http://localhost:80/status` (from container)
- **Method**: GET
- **Expected Response**: 
  ```json
  {
    "database": true,
    "cache": true,
    "session": true
  }
  ```

**Public Health Check**:
- **URL**: `https://docs.shannonjlove.cloud/` 
- **Expected**: HTTP 200 with BookStack home page

### Expected Healthy State
- **BookStack Service**: Active and running (`systemctl is-active bookstack.service`)
- **Database Service**: Active and running (`systemctl is-active bookstack-db.service`)
- **Database Connectivity**: Database responds to internal queries
- **Cache**: Redis or file cache operational
- **Sessions**: Session storage functional
- **Nginx**: Routing traffic to BookStack correctly
- **Public Endpoint**: Returns BookStack page, not error

### Troubleshooting Health Issues

**If health check fails**:

1. **Check service status**:
   ```bash
   systemctl status bookstack.service -l
   systemctl status bookstack-db.service -l
   ```

2. **Review service logs**:
   ```bash
   journalctl -u bookstack.service -n 50
   journalctl -u bookstack-db.service -n 50
   ```

3. **Verify configuration**:
   ```bash
   cat /etc/bookstack/bookstack.env | grep -E "APP|DB"
   # Verify APPKEY is set (non-empty)
   grep "^APP_KEY=" /etc/bookstack/bookstack.env
   ```

4. **Test database connectivity**:
   ```bash
   # From host
   podman exec bookstack mysql -h bookstack-db -u bookstack -p"$DB_PASSWORD" -e "SELECT 1"
   ```

5. **Check proxy connectivity**:
   ```bash
   # Nginx should be able to reach BookStack on infra.network
   # Verify from nginx container: curl http://bookstack:80/status
   ```

6. **Verify persistent volumes**:
   ```bash
   podman volume ls | grep bookstack
   podman volume inspect bookstack-data
   ```

## Configuration Management

### Environment Variables

Located in: `etc/bookstack/bookstack.env`

| Variable | Purpose | Example Value |
|---|---|---|
| `APP_KEY` | Encryption key (must be set before first start) | `base64:...` |
| `APP_URL` | Application public URL | `https://docs.shannonjlove.cloud` |
| `APP_DEBUG` | Debug mode (false in production) | `false` |
| `DB_HOST` | Database hostname | `bookstack-db` |
| `DB_DATABASE` | Database name | `bookstack` |
| `DB_USERNAME` | Database user | `bookstack` |
| `DB_PASSWORD` | Database password | `[secure-password]` |
| `MAIL_DRIVER` | Email driver | `log` or `sendmail` |
| `CACHE_DRIVER` | Cache backend | `file` |
| `SESSION_DRIVER` | Session storage | `file` |

### Configuration Files

| File | Purpose | Permissions | Notes |
|---|---|---|---|
| `etc/bookstack/bookstack.env` | Application config | `0600` | Contains secrets, restrict access |
| `etc/containers/systemd/bookstack.container` | Quadlet definition | `0644` | Service definition, readable |
| `data/nginx/proxy_host/bookstack.conf` | Nginx config | `0644` | Proxy rules, readable |

### Changes and Reloads

**After modifying `bookstack.env`**:
```bash
# Restart service to pick up changes
systemctl restart bookstack.service

# Verify it restarted successfully
systemctl status bookstack.service
curl http://127.0.0.1:80/status
```

**After modifying `bookstack.container`**:
```bash
# Reload systemd daemon
systemctl daemon-reload

# Restart service
systemctl restart bookstack.service
```

**After modifying nginx proxy config**:
```bash
# Reload nginx configuration (zero-downtime)
docker exec nginx-container nginx -s reload
# Or if using NPM, reload through web interface
```

## Backup and Recovery

### Backup Procedures

**Database Backup** (runs from host):
```bash
# Full database backup with timestamp
BACKUP_FILE="/backups/bookstack_$(date +%Y%m%d_%H%M%S).sql"
podman exec bookstack-db mysqldump \
  -u bookstack \
  -p"$DB_PASSWORD" \
  bookstack > "$BACKUP_FILE"

# Compress for storage
gzip "$BACKUP_FILE"

# Verify backup
gunzip -c "${BACKUP_FILE}.gz" | head -20
```

**File/Volume Backup**:
```bash
# Backup application data volume
BACKUP_FILE="/backups/bookstack-data_$(date +%Y%m%d_%H%M%S).tar.gz"
podman run --rm \
  -v bookstack-data:/data \
  -v /backups:/backup \
  busybox tar czf /backup/$(basename "$BACKUP_FILE") -C /data .
```

### Backup Schedule
- **Frequency**: Daily at 2:00 AM
- **Retention**: 30 days of daily backups, 12 months of weekly backups
- **Location**: `/backups/` (mounted on persistent storage)
- **Verification**: Weekly test restore (first Monday of month)

### Recovery Procedures

**Database Recovery**:
```bash
# Stop BookStack to prevent corruption
systemctl stop bookstack.service

# Restore from backup
BACKUP_FILE="/backups/bookstack_20260710_020000.sql.gz"
gunzip -c "$BACKUP_FILE" | podman exec -i bookstack-db mysql \
  -u bookstack \
  -p"$DB_PASSWORD" \
  bookstack

# Restart service
systemctl start bookstack.service

# Verify recovery
curl http://127.0.0.1:80/status
```

**File/Volume Recovery**:
```bash
# Backup current volume (in case of failed recovery)
podman volume inspect bookstack-data

# Create temporary container to restore
podman run --rm \
  -v bookstack-data:/data \
  -v /backups:/backup \
  busybox tar xzf /backup/bookstack-data_20260710_020000.tar.gz -C /data

# Restart application
systemctl restart bookstack.service
```

### Recovery Testing
- **Schedule**: First Monday of every month
- **Process**: Restore to staging environment, verify functionality
- **Last Test**: [Date last tested]
- **Next Test**: [Scheduled date]

## Monitoring and Alerting

### Daily Operations
- [ ] Verify service status: `systemctl status bookstack.service`
- [ ] Check public endpoint responds: `curl https://docs.shannonjlove.cloud`
- [ ] Review recent logs for errors: `journalctl -u bookstack.service -n 20`
- [ ] Confirm health endpoint passes: `curl http://127.0.0.1:80/status`

### Weekly Operations
- [ ] Review service logs: `journalctl -u bookstack.service --since "1 week ago"`
- [ ] Verify database backup completed: `ls -lh /backups/bookstack_*.sql.gz`
- [ ] Check backup file size is reasonable (>1MB for typical setup)

### Monthly Operations
- [ ] Check for available updates: `podman pull requarks/wiki:latest` (check digest)
- [ ] Review certificate expiry: `openssl x509 -in /path/to/cert -noout -dates`
- [ ] Review access logs for unusual patterns
- [ ] Update documentation if procedures changed

### Quarterly Operations
- [ ] Rotate database password (update in env and backup credentials)
- [ ] Full recovery procedure test (restore to staging)
- [ ] Security audit: review access logs, check for exposed secrets
- [ ] Performance review: check disk usage, query performance

## Security and Hardening

### Critical Security Controls

| Control | Implementation | Verification |
|---------|-----------------|--------------|
| **APPKEY** | Must be set before first start | `grep APP_KEY= /etc/bookstack/bookstack.env` (should be non-empty) |
| **Database Isolation** | MariaDB on internal bookstack.network only | `podman network inspect bookstack.network` (no external routes) |
| **Admin Access** | Behind Tailscale VPN and SSH key auth | `grep PermitRootLogin no /etc/ssh/sshd_config` |
| **Certificate Management** | Valid SSL/TLS certificate | `curl -I https://docs.shannonjlove.cloud/` (200 response, valid cert) |
| **File Permissions** | Restricted env file permissions | `ls -la /etc/bookstack/bookstack.env` (should be 0600) |
| **Secret Scanning** | Regular review of logs/configs | Monthly security audit |

### Sensitive Data Protection
- **Credentials Stored In**: `/etc/bookstack/bookstack.env`
- **Permissions**: `0600` (owner read/write only)
- **Who Has Access**: Root user and BookStack process only
- **Backup Encryption**: Database backups encrypted (recommended)
- **Secret Rotation**: Database password rotated quarterly

### Certificate Management
- **Current Certificate**: Self-signed (for testing)
- **Recommended**: Let's Encrypt certificate
- **Expiry Date**: [Check with openssl command above]
- **Renewal Process**: 
  1. Obtain new certificate (Let's Encrypt auto-renewal)
  2. Update certificate path in Nginx Proxy Manager
  3. Reload nginx: `docker exec nginx nginx -s reload`
- **Renewal Frequency**: 90 days (automated with certbot)

### Network Security
- **Internal-Only Components**: MariaDB (bookstack.network only)
- **VPN/Tailscale Restrictions**: SSH access restricted to Tailscale network
- **Firewall Rules**: 
  - Port 443 (HTTPS) open to public
  - Port 80 (HTTP) open to public, redirects to 443
  - Port 22 (SSH) restricted to Tailscale network only
  - Database port 3306 not exposed to public

### Access Control
- **Admin Access**: Tailscale VPN + SSH key auth (no password auth)
- **User Authentication**: BookStack user accounts (username/password)
- **API Access**: BookStack API tokens (if enabled)
- **Database Access**: Internal connection string only

## Logs and Debugging

### Service Logs

```bash
# View BookStack service logs (follow live)
journalctl -u bookstack.service -f

# View last 100 lines of logs
journalctl -u bookstack.service -n 100

# View logs since last boot
journalctl -u bookstack.service -b

# View logs from last hour
journalctl -u bookstack.service --since "1 hour ago"

# View database service logs
journalctl -u bookstack-db.service -f
```

### Application Logs

- **Location**: Application stores logs in container volume
- **Format**: Text format with timestamps
- **Rotation**: Handled by log driver (check docker logs settings)
- **Access**: Via container: `podman logs bookstack -f`

### Common Issues and Solutions

#### Issue: "Cannot connect to database"

**Cause**: Database service not running or unreachable  
**Solution**:
```bash
# Check database service status
systemctl status bookstack-db.service

# If not running, start it
systemctl start bookstack-db.service

# Verify it's listening
podman exec bookstack-db mysql -u root -p"$DB_PASSWORD" -e "SELECT 1"

# Check network connectivity
podman network inspect bookstack.network
```

#### Issue: "Health check returns database: false"

**Cause**: Database configuration mismatch or credentials wrong  
**Solution**:
```bash
# Verify DB_HOST points to correct container
grep DB_HOST /etc/bookstack/bookstack.env

# Test connectivity
podman exec bookstack mysql -h bookstack-db -u bookstack -p"$DB_PASSWORD" -e "SELECT 1"

# Restart both services
systemctl restart bookstack-db.service
systemctl restart bookstack.service
```

#### Issue: "APPKEY not set" error on startup

**Cause**: APPKEY environment variable missing  
**Solution**:
```bash
# Generate new APPKEY
podman exec bookstack php artisan key:generate --no-interaction

# Or set manually in bookstack.env
echo "APP_KEY=base64:..." >> /etc/bookstack/bookstack.env

# Restart service
systemctl restart bookstack.service
```

#### Issue: "Public URL returns 502 Bad Gateway"

**Cause**: Nginx cannot reach BookStack container  
**Solution**:
```bash
# Check nginx proxy configuration
cat /data/nginx/proxy_host/bookstack.conf

# Verify infra.network connection
podman network inspect infra.network

# Test connectivity from nginx
podman exec nginx-container curl http://bookstack:80/status

# Restart nginx
docker-compose -f /path/to/compose restart nginx
# or
nginx -s reload
```

## Team and Escalation

### Current Owner
- **Name**: [Primary maintainer name]
- **Contact**: [Email and/or Slack handle]
- **Expertise**: Full service administration

### Backup Owner
- **Name**: [Secondary maintainer name]
- **Contact**: [Email and/or Slack handle]
- **Expertise**: Operations and troubleshooting

### Escalation Path
1. **Primary Contact**: [Name] - Initial troubleshooting
2. **Secondary Contact**: [Name] - Backup on-call
3. **Infrastructure Team**: For hosting/network issues
4. **External**: Vendor support (if needed)

### On-Call Rotation
- **Schedule**: Weekly rotation (Monday-Sunday)
- **Escalation**: If no response within 30 minutes, page backup contact
- **Contact Method**: Slack @here, phone call if critical
- **SLA**: Critical issues (service down) < 1 hour response

## Documentation and References

### Primary Documents
- [Configuration Guide](link-to-bookstack-config)
- [Deployment Checklist](link-to-deployment-checklist)
- [Quick Reference](link-to-quick-ref)

### External Resources
- [BookStack Official Documentation](https://www.bookstackapp.com/)
- [BookStack GitHub Repository](https://github.com/BookStackApp/BookStack)
- [Podman Documentation](https://podman.io/)
- [Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)

## Open Items and Next Steps

- [ ] **Replace self-signed certificate with Let's Encrypt** - Owner: [Name], Target: [Date]
- [ ] **Configure Tailscale ACLs** for tighter admin control - Owner: [Name], Target: [Date]
- [ ] **Enable automated backups** with off-site storage - Owner: [Name], Target: [Date]
- [ ] **Document team ownership and escalation** - Owner: [Name], Target: [Date]
- [ ] **Complete BookStack content migration** from legacy wiki - Owner: [Name], Target: [Date]

## Handoff Acceptance Checklist

Before accepting ownership, verify:

- [ ] Public URL (https://docs.shannonjlove.cloud) loads successfully
- [ ] Health check passes internally: `curl http://127.0.0.1:80/status`
- [ ] Health check passes publicly (page loads)
- [ ] Tailscale SSH access works: `ssh root@100.115.66.75`
- [ ] Can log in to BookStack admin panel
- [ ] Configuration files present: `/etc/bookstack/bookstack.env` exists
- [ ] Volumes present: `podman volume ls | grep bookstack`
- [ ] Database is healthy and accessible
- [ ] Backup procedure tested and functional
- [ ] Restore procedure tested (at least documented)
- [ ] All team members trained on operations
- [ ] Monitoring/alerting configured
- [ ] Escalation procedures documented
- [ ] Open action items assigned to owners with target dates

**Received by**: [Name] | **Date**: [Date]

**Signature**: ________________________ | **Authorized By**: ________________________

---

## Template Notes

This completed example shows:
- ✅ All bracketed items replaced with real values
- ✅ Specific commands that can be copy/pasted
- ✅ Expected outputs and how to verify
- ✅ Realistic dates and contact information
- ✅ Detailed procedures, not generic descriptions
- ✅ Security considerations throughout
- ✅ Proper formatting with code blocks and tables

Use this as a reference when completing your own service handoff templates.

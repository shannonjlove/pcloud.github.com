---
layout: page
title: System Architecture & Best Practices
permalink: /architecture/
---

# Media Management System Architecture & Best Practices

Comprehensive guide to optimal system design, data flow, and operational patterns.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Data Flow & Integration](#data-flow--integration)
3. [Storage Strategy](#storage-strategy)
4. [Performance Optimization](#performance-optimization)
5. [Security & Access Control](#security--access-control)
6. [Disaster Recovery](#disaster-recovery)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Scalability Considerations](#scalability-considerations)

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     External Sources                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Torbox    │  │  Direct Copy │  │   Streaming  │      │
│  │  (Torrents)  │  │   (Manual)   │  │   (HTTP)     │      │
│  └──────────┬───┘  └──────┬───────┘  └──────┬───────┘      │
└─────────────┼─────────────┼──────────────────┼──────────────┘
              │             │                  │
              ▼             ▼                  ▼
        ┌──────────────────────────────────────────┐
        │   Local Storage (Primary Tier)           │
        │   /media (SSD or fast drive)             │
        │  - movies/                               │
        │  - tv/                                   │
        │  - music/                                │
        │  - torrents/                             │
        └──────────┬───────────────────────────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
  ┌────────┐ ┌──────────┐ ┌──────────┐
  │  Local │ │ Jellyfin │ │  rclone  │
  │ rsync  │ │  Server  │ │  daemon  │
  │ backup │ └──────────┘ │  (mount) │
  └────┬───┘       │       └────┬─────┘
       │           │            │
       ▼           ▼            ▼
  ┌──────────┐ ┌────────┐ ┌──────────┐
  │ External │ │  IINA  │ │ IDrive   │
  │   HDD    │ │ Player │ │   E2     │
  │ Backup   │ │(Playback)│ │ Storage  │
  └──────────┘ └────────┘ └──────────┘
       │
       └──────────────────────┐
                              │
                    ┌─────────▼──────────┐
                    │  Weekly Verify &   │
                    │  Monthly Restore   │
                    │  Test              │
                    └────────────────────┘
```

### Component Roles

| Component | Purpose | Access | Redundancy |
|-----------|---------|--------|-----------|
| Local Storage | Primary working media | Direct/Local | SSD/RAID |
| External HDD | Backup tier | Scheduled rsync | 1-2 copies |
| IDrive E2 | Archive/Disaster Recovery | Rclone sync | Cloud redundancy |
| Jellyfin | Media playback server | Web/API | Container |
| IINA | Direct playback | Local/Network | Client |
| Rclone | Cloud sync tool | CLI/Daemon | N/A |
| Rsync | Local backup | Cron/Manual | Script |

---

## Data Flow & Integration

### Daily Workflow

```
Day 0:
├─ Torbox downloads complete
└─ Files land in ~/Media/torrents/

Day 0 - 3:00 AM:
├─ Cron triggers backup-media-automation.sh
├─ rsync syncs ~/Media → /backup/media
└─ Logs written to ~/.backup-media-logs/

Day 0 - 4:00 AM (Sunday):
├─ rclone syncs ~/Media → idrive-e2:media-storage
├─ Checksum verification (one-way)
└─ Status report generated

Continuous:
├─ Jellyfin serves media
├─ IINA plays local or networked videos
└─ Rclone mount available for cloud access
```

### Integration Points

#### 1. Torbox → Local Storage
```
Torbox API
   ↓
Download Handler
   ↓
~/Media/torrents/
   ↓
Auto-import (optional)
   ↓
Jellyfin Library Scan
```

#### 2. Local → External Backup
```
rsync daemon
   ↓
File comparison
   ↓
Selective sync
   ↓
/backup/media/
   ↓
Verification
```

#### 3. Local → Cloud Archive
```
rclone sync
   ↓
S3 upload
   ↓
idrive-e2:media-storage
   ↓
Checksum validation
   ↓
Completion report
```

#### 4. Cloud → Jellyfin (Read-Only)
```
rclone mount
   ↓
Virtual filesystem
   ↓
~/mnt/idrive/
   ↓
Jellyfin can read (slow)
   ↓
Not recommended for real-time playback
```

---

## Storage Strategy

### Three-Tier Storage Model

#### Tier 1: HOT (Local SSD)
- **Purpose:** Active media, frequently accessed
- **Size:** 500GB - 2TB
- **Technology:** SSD/NVMe
- **Access Pattern:** Direct, fast
- **Cost:** $0.05-0.10 per GB/month
- **Retention:** 1-2 weeks active rotation

Example:
```
~/Media/torrents/  ← New downloads (7-day rotation)
~/Media/movies/    ← Recently watched
~/Media/tv/        ← Active TV series
```

#### Tier 2: WARM (External HDD)
- **Purpose:** Backup, archive
- **Size:** 2TB - 10TB
- **Technology:** External HDD (USB 3.1)
- **Access Pattern:** Weekly/Monthly restore tests
- **Cost:** $15-50/year
- **Retention:** 12-24 months

Example:
```
/backup/media/     ← Weekly rsync backup
/backup/archive/   ← Monthly full copies
/backup/manifest/  ← File lists & checksums
```

#### Tier 3: COLD (Cloud Archive)
- **Purpose:** Disaster recovery, long-term archive
- **Size:** Unlimited (scalable)
- **Technology:** S3-compatible (IDrive E2)
- **Access Pattern:** Rare, emergency only
- **Cost:** $0.015/GB/month (IDrive E2)
- **Retention:** Indefinite

Example:
```
idrive-e2:media-storage/movies/   ← Replicated movies
idrive-e2:media-storage/tv/       ← Replicated shows
idrive-e2:media-storage/archive/  ← Old library versions
```

### Data Movement Strategy

```
New Files
  ├─ HOT (Local SSD)
  ├─ T0 + 1 day → WARM (External HDD)
  ├─ T0 + 7 days → COLD (Cloud Archive)
  └─ Older → Automated cleanup or long-term archive

Access Patterns:
  Recent (< 7 days): HOT tier (SSD speed)
  Medium (7-30 days): WARM tier (weekly backups)
  Old (> 30 days): COLD tier (archive only)
```

---

## Performance Optimization

### Network Performance

#### Local Playback
```
Jellyfin → Direct playback
├─ No transcoding needed
├─ Original quality (bitrate agnostic)
├─ Recommended for 4K content
└─ Performance: Excellent
```

#### Remote Playback (Over Internet)
```
Jellyfin → Transcode → Network
├─ Transcoding: 1080p 5Mbps recommended
├─ Bitrate: 2-5 Mbps for 1080p
├─ Quality: Adaptive quality available
└─ Performance: Good with proper settings
```

#### Cloud Media (Not Recommended)
```
Rclone mount → S3 read → Jellyfin
├─ Latency: 100-500ms per request
├─ Throughput: 1-5 Mbps
├─ Not suitable for real-time playback
├─ Use case: Rare archive access only
└─ Performance: Poor for playback
```

### Optimization Techniques

#### Rclone Performance
```bash
# Fast sync with good defaults
rclone sync /media idrive-e2:media-storage \
  --fast-list \
  --s3-no-check-bucket \
  --s3-upload-concurrency 5 \
  --checksum \
  --progress

# Cache frequently accessed metadata
rclone mount idrive-e2:media-storage /mnt/idrive \
  --dir-cache-time 24h \
  --vfs-cache-mode full \
  --vfs-cache-max-age 24h
```

#### Jellyfin Performance
```
Docker configuration:
- Memory: 2-4 GB minimum
- Cores: 2 cores minimum
- Transcoding: Disable for LAN playback
- Cache: Use fast SSD for cache directory
- HTTPS: Use reverse proxy with TLS termination

Playback settings:
- Video codec: Direct play (no transcode) for 1080p
- Audio: Direct play MP3/AAC
- Subtitles: Client-side handling
```

#### Rsync Performance
```bash
# Optimized rsync for large files
rsync -avz \
  --compress-choice=zstd \
  --checksum \
  --partial \
  --partial-dir=.rsync-partial \
  --progress \
  /media/ /backup/media/

# For slow network links
rsync -avz --bwlimit=10000 /media/ /backup/media/
```

---

## Security & Access Control

### Authentication & Authorization

#### Jellyfin Access
```
Settings → Users:
- Admin account: Strong password (16+ chars)
- Limited accounts: Restrict to specific libraries
- API keys: For external app access
- Session tokens: Expire after 30 days

Remote access:
- Use reverse proxy with TLS
- Enable rate limiting
- Restrict API to authenticated users
- Monitor access logs
```

#### Rclone Security
```bash
# Encrypt credentials
rclone obscure YOUR_SECRET_KEY
# Store in ~/.config/rclone/rclone.conf

# Use IAM credentials (not root access)
# IDrive E2: Create bucket-specific IAM user

# Restrict S3 permissions
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::media-storage/*"
    }
  ]
}
```

#### Local Access
```bash
# File permissions
chmod 755 ~/Media              # Directory readable
chmod 644 ~/Media/**/*.mp4     # Media files readable
chmod 700 ~/.backup-media-logs # Logs private

# User/Group ownership
chown -R user:group ~/Media
chown -R user:group ~/.backup-media-logs
```

### Network Security

#### Firewall Rules
```
Local Network:
├─ Port 8096 (Jellyfin): Restrict to home network
├─ Port 6787 (rclone): Restrict to localhost only
└─ UPnP: Disable for security

Internet (via Reverse Proxy):
├─ HTTPS only (TLS 1.2+)
├─ Cloudflare/Proxy for hiding IP
├─ Rate limiting enabled
└─ WAF rules for API
```

#### VPN for Remote Access
```
Recommended setup:
1. Don't expose Jellyfin directly
2. Use VPN (WireGuard/OpenVPN) for access
3. Connect via VPN → access local Jellyfin
4. OR use Jellyfin official remote app (built-in proxy)
5. OR reverse proxy with authentication

Benefits:
- Encrypted connection
- Hide server IP
- Additional authentication layer
- Prevent direct attacks
```

### Data Protection

#### Encryption at Rest
```
IDrive E2:
- Bucket encryption: S3-managed (SSE-S3)
- Or client-side encryption: rclone crypt wrapper

Local Storage:
- External HDD: Full-disk encryption (BitLocker/LUKS)
- SSD: Hardware encryption (eSSD standard)

Backup:
- Sensitive data: Encrypt before backup
- Use rclone-crypt for sensitive libraries
```

#### Encryption in Transit
```
Jellyfin:
- HTTPS only (reverse proxy)
- Certificate: Let's Encrypt (auto-renew)
- TLS 1.2 minimum

Rclone:
- TLS to IDrive E2: Enforced
- Connection: Encrypted S3 (https://)
- Checksum: Verify data integrity
```

---

## Disaster Recovery

### Backup Strategy

#### Frequency
```
Daily:     Local metadata backup (fast)
Weekly:    Full filesystem backup (rsync)
Monthly:   Verify from cold storage (test restore)
Quarterly: Update encryption & test edge cases
Annually:  Document and review procedures
```

#### Backup Checklist
```
Before backup:
- [ ] Free disk space (20% of source)
- [ ] Verify network connectivity
- [ ] Check backup drive is mounted
- [ ] Review recent log files

After backup:
- [ ] Verify file counts match
- [ ] Check total sizes are reasonable
- [ ] Validate checksums (if enabled)
- [ ] Generate manifest
- [ ] Archive backup report
```

### Recovery Procedures

#### Quick Recovery (< 1 hour)
```bash
# Restore from external HDD
rsync -avz --progress \
  /backup/media/movies/ \
  ~/Media/movies/

# Verify restoration
rclone check ~/Media /backup/media --one-way
```

#### Full Recovery (< 24 hours)
```bash
# Restore from IDrive E2
rclone sync idrive-e2:media-storage \
  ~/Media \
  --progress \
  --checksum

# Monitor progress
watch -n 5 'rclone du idrive-e2:media-storage'
```

#### Partial Recovery (Specific Files)
```bash
# Restore single library
rclone copy idrive-e2:media-storage/movies \
  ~/Media/movies \
  --progress

# Restore specific file
rclone copy idrive-e2:media-storage/movies/Avatar.mkv \
  ~/Media/movies/ \
  --progress
```

#### Recovery Testing Schedule
```
Monthly:
- Test restore from external HDD
- Verify file integrity
- Time recovery process

Quarterly:
- Full restore to test environment
- Test with actual playback
- Verify all formats work

Annually:
- Document recovery time (RTO)
- Calculate recovery point objective (RPO)
- Update recovery runbooks
```

---

## Monitoring & Maintenance

### Health Checks

#### Daily Monitoring
```bash
#!/bin/bash
# Check backup health

echo "=== Storage Health ==="
du -sh ~/Media ~/Media/*
du -sh /backup/media

echo "=== Last Backup ==="
ls -lh ~/.backup-media-logs/ | tail -5

echo "=== Jellyfin Health ==="
curl -s http://localhost:8096/System/Ping

echo "=== Cron Jobs ==="
crontab -l | grep -E '(backup|rclone|rsync)'

echo "=== Recent Errors ==="
tail -20 ~/.backup-media-logs/*.log | grep -i error
```

#### Weekly Verification
```bash
#!/bin/bash
# Weekly backup verification

echo "Comparing local vs backup..."
rclone check ~/Media /backup/media --one-way

echo "Comparing local vs cloud..."
rclone check ~/Media idrive-e2:media-storage --one-way

echo "File count comparison..."
echo "Local: $(find ~/Media -type f | wc -l)"
echo "Backup: $(find /backup/media -type f | wc -l)"
echo "Cloud: $(rclone count idrive-e2:media-storage)"
```

#### Monthly Reports
```
Generate comprehensive report:
1. Storage usage trends
2. Backup success rates
3. Recovery readiness
4. Security audit
5. Cost analysis
6. Performance metrics
7. Incident log
```

### Maintenance Schedule

#### Daily (Automated)
- Cron backup execution
- Log rotation
- Temporary file cleanup

#### Weekly (Manual)
- Verify backup integrity
- Check disk space
- Review error logs
- Update Jellyfin metadata

#### Monthly (Planned)
- Performance optimization
- Security audit
- Test recovery procedure
- Capacity planning
- Cost review

#### Quarterly (Strategic)
- Update tool versions
- Review architecture
- Security penetration testing
- Disaster recovery drill
- Documentation update

#### Annually (Comprehensive)
- Full system audit
- Cost-benefit analysis
- Technology refresh evaluation
- Compliance check
- Plan for next year

---

## Scalability Considerations

### When to Expand

#### Local Storage
```
Current: < 1 TB
Action: Add external SSD

Current: 1-5 TB
Action: RAID array or larger external drive

Current: > 5 TB
Action: NAS (Network Attached Storage)
```

#### Backup Strategy
```
Current: Single external drive
Expand: Add 2-3 rotation drives
        Geographic distribution (off-site)

Current: IDrive E2 only
Expand: Add secondary cloud provider
        Multi-region replication
```

#### Media Server
```
Current: Single Jellyfin instance
Expand: Load balancer + multiple instances
        Separate transcode server
        Dedicated cache server

Current: 1-2 concurrent users
Expand: 3-5 users: Upgrade hardware
        5+ users: Multi-server architecture
```

### Growth Projections

```
Scenario: Family streaming + archival

Year 1: 2 TB (movies, TV, photos)
├─ Local: 500 GB
├─ Backup: 500 GB
└─ Cloud: 1 TB

Year 3: 8 TB
├─ Local: 2 TB (RAID1)
├─ Backup: 3 TB (2 rotations)
└─ Cloud: 3 TB

Year 5: 20 TB
├─ Local: 5 TB (RAID1 or NAS)
├─ Backup: 8 TB (3 rotations + off-site)
└─ Cloud: 7 TB (tiered storage)
```

### Cost Optimization

#### Current Setup (2 TB)
```
IDrive E2 Storage: $3/month
External HDD (amortized): $5/month
Electricity (backup/sync): $2/month
─────────────────────────
Total: ~$10/month
```

#### Scaled Setup (20 TB)
```
IDrive E2 Storage: $30/month
External HDDs (4×) (amortized): $15/month
NAS Hardware (amortized): $25/month
Electricity: $10/month
─────────────────────────
Total: ~$80/month

Per TB: $4/month (vs. $5/month originally)
Cost improves with scale
```

---

## Quick Reference

### Performance Targets
| Operation | Target | Actual |
|-----------|--------|--------|
| Local playback | < 1s | Excellent |
| Cloud sync | 100 MB/min | 50-150 MB/min |
| Restore time (1 TB) | < 4 hours | 2-6 hours |
| Backup frequency | Daily | 1x/day automated |

### Capacity Planning
| Component | Used | Available | Action |
|-----------|------|-----------|--------|
| Local SSD | 1.8 TB | 0.2 TB | Expand soon |
| External HDD | 1.5 TB | 3.5 TB | OK |
| IDrive E2 | 2.0 TB | Unlimited | OK |

### Alert Thresholds
| Metric | Warning | Critical |
|--------|---------|----------|
| Local disk | 80% full | 95% full |
| Backup delay | 48 hours | 7 days |
| Cloud sync | 100 GB | 500 GB |
| Error rate | 1% | 5% |

---

## References

- [Three-Tier Storage Architecture](https://en.wikipedia.org/wiki/Tiered_storage)
- [RPO vs RTO](https://www.veeam.com/blog/rpo-rto.html)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BestPractices.html)


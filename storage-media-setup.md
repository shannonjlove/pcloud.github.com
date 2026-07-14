---
layout: page
title: Storage & Media Management Integration Guide
permalink: /storage-media-setup/
---

# Complete Storage & Media Management Integration Guide

This guide provides best practices for integrating rclone, rsync, idrive e2, torbox, Jellyfin, and iina into a seamless media management workflow.

## Architecture Overview

```
Torbox (Torrents)
      ↓
Local Storage (Fast Tier)
      ↓ (rsync backup)
idrive e2 (Cold Tier/Backup)
      ↓ (rclone mount)
Jellyfin (Media Server)
      ↓
iina (macOS Player)
```

---

## 1. IDrive E2 S3 Configuration

### 1.1 Create IDrive E2 Bucket
- **Portal:** https://www.idrive.com/e2/
- Create bucket: `media-storage` (or your preferred name)
- Create IAM credentials for API access
- Note your access key, secret key, and endpoint URL

### 1.2 Optimal Settings
```
Region: Closest to your location
Bucket Name: media-storage
Versioning: Disabled (unless needed for backup recovery)
Lifecycle: Archive old files after 90 days (cost optimization)
```

---

## 2. Rclone Configuration (S3 Backend)

### 2.1 Install & Setup
```bash
# macOS
brew install rclone

# Linux
sudo apt install rclone

# Windows
choco install rclone
```

### 2.2 Configure Remote for IDrive E2
```bash
rclone config
# When prompted:
# Name: idrive-e2
# Storage type: s3
# Provider: Other
# Access Key: [Your IDrive E2 Access Key]
# Secret Key: [Your IDrive E2 Secret Key]
# Region: us-east-1 (or your region)
# Endpoint: https://s3.e2.wasabisys.com (or appropriate IDrive E2 endpoint)
# Bucket: media-storage
# ACL: private
```

### 2.3 Test Connection
```bash
rclone ls idrive-e2:media-storage
rclone du idrive-e2:media-storage
```

### 2.4 Common Rclone Operations
```bash
# Sync LOCAL → idrive e2 (backup)
rclone sync /path/to/media idrive-e2:media-storage --progress

# Sync idrive e2 → LOCAL (restore)
rclone sync idrive-e2:media-storage /path/to/media --progress

# Bi-directional sync (careful with this)
rclone sync idrive-e2:media-storage /path/to/media --backup-dir=/backup
rclone sync /path/to/media idrive-e2:media-storage --backup-dir=/backup

# Mount idrive e2 as virtual drive (macOS/Linux)
rclone mount idrive-e2:media-storage ~/mnt/idrive --read-only --daemon

# Copy specific files with checksums
rclone copy /path/to/media idrive-e2:media-storage --checksum --progress
```

### 2.5 Performance Tuning
```bash
# ~/.config/rclone/rclone.conf
[idrive-e2]
type = s3
provider = Other
access_key_id = YOUR_KEY
secret_access_key = YOUR_SECRET
endpoint = https://s3.e2.wasabisys.com
region = us-east-1
bucket = media-storage
acl = private

# Performance settings (add to remote section)
upload_concurrency = 5
max_retries = 5
retries = 3
skip_links = true
no_check_certificate = false
```

---

## 3. Rclone GUI Setup

### 3.1 Installation
```bash
# Download from: https://github.com/kapitainsky/RcloneNg
# or macOS
brew install rclone-ng

# Launches web interface
rclone-ng
```

### 3.2 Usage
- Access at: `http://localhost:5575`
- Create jobs for scheduled syncs
- Set up automated backups with cron

### 3.3 Recommended GUI Jobs

**Job 1: Daily Backup to idrive e2**
```
Source: /path/to/local/media
Destination: idrive-e2:media-storage
Schedule: 0 2 * * * (Daily at 2 AM)
Options: --progress --verbose --checksum
```

**Job 2: Weekly Cleanup**
```
Source: idrive-e2:media-storage
Options: --delete-empty-src-dirs
```

---

## 4. Rsync Configuration & Best Practices

### 4.1 Installation
```bash
# macOS
brew install rsync

# Linux
sudo apt install rsync

# Windows (via WSL or Git Bash)
sudo apt install rsync
```

### 4.2 Local Backup Strategy
```bash
# Backup to external drive weekly
rsync -avz --delete --progress \
  /path/to/media/ \
  /Volumes/backup-drive/media-backup/ \
  --exclude='*.tmp' --exclude='.*'

# Using rclone + rsync for dual backup
rsync -avz /path/to/media/ /local/backup/
rclone sync /path/to/media idrive-e2:media-storage --progress
```

### 4.3 Rsync Cron Job (macOS/Linux)
```bash
# Edit crontab: crontab -e

# Daily local backup at 3 AM
0 3 * * * rsync -avz --delete /path/to/media/ /backup/media/ >> ~/rsync.log 2>&1

# Weekly idrive e2 sync at 4 AM Sunday
0 4 * * 0 /usr/local/bin/rclone sync /path/to/media idrive-e2:media-storage >> ~/rclone.log 2>&1
```

### 4.4 Key Rsync Options
```
-a, --archive       Preserve permissions, timestamps, etc.
-v, --verbose       Verbose output
-z, --compress      Compress data during transfer
--progress          Show progress
--delete            Delete extraneous files
--exclude           Exclude patterns
--checksum          Use checksums instead of modification times
--partial           Keep partial transfers for resume
--timeout=30        Set timeout in seconds
```

---

## 5. Torbox Integration

### 5.1 Installation & Configuration
```bash
# Torbox is a service, configure via web interface
# https://www.torbox.app/

# API Configuration:
1. Get API key from Torbox dashboard
2. Configure download location to /path/to/torrents/
3. Enable auto-import to Jellyfin directory (optional)
```

### 5.2 Optimal Setup
```
Download Folder: /path/to/media/torrents/
Cleanup: Auto-remove torrents after 7 days seeding
Import: Move completed downloads to /path/to/media/libraries/
```

### 5.3 Integration with Jellyfin
```bash
# Add torrent folder as Jellyfin library source
/path/to/media/torrents/ → Jellyfin Movies/TV Shows

# Auto-cleanup script
#!/bin/bash
# ~/scripts/cleanup-torrents.sh
find /path/to/media/torrents/ -type f -mtime +7 -delete
# Add to crontab: 0 5 * * * ~/scripts/cleanup-torrents.sh
```

---

## 6. Jellyfin Media Server Configuration

### 6.1 Installation

**Docker (Recommended)**
```bash
docker run -d \
  --name=jellyfin \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -v /path/to/jellyfin/config:/config \
  -v /path/to/media:/media:ro \
  -p 8096:8096 \
  --restart unless-stopped \
  jellyfin/jellyfin:latest
```

**Bare Metal (macOS)**
```bash
brew install jellyfin
brew services start jellyfin
# Access at: http://localhost:8096
```

### 6.2 Library Configuration

**Add Libraries:**
```
Movies:
  Path: /path/to/media/movies
  Type: Movies
  
TV Shows:
  Path: /path/to/media/tv
  Type: TV Shows
  
Music:
  Path: /path/to/media/music
  Type: Music
```

### 6.3 Optimal Settings

**Playback**
- Transcoding: Enable (server quality adapts to client)
- Hardware acceleration: Enable if available (GPU)
- Subtitle burning: Disabled (let clients handle)

**Library**
- Auto-refresh every 12 hours
- Enable metadata fetching from TMDB/TheTVDB
- Skip empty folders: Enabled

**Performance**
```
Maximum concurrent transcodes: 2
Temporary transcode directory: /tmp/jellyfin-transcode
Enable low bandwidth mode for remote access
```

### 6.4 Using Rclone Mount with Jellyfin
```bash
# Mount idrive e2 for remote media access
rclone mount idrive-e2:media-storage ~/mnt/idrive \
  --allow-other \
  --dir-cache-time 24h \
  --cache-dir /tmp/rclone-cache \
  --cache-db-path /tmp/rclone-cache-db \
  --daemon

# Add ~/mnt/idrive to Jellyfin as library source
# Note: Performance will be slower than local storage
```

---

## 7. IINA Media Player (macOS)

### 7.1 Installation
```bash
brew install iina
```

### 7.2 Configuration
```
Preferences → General:
  - Auto pause when switching to other apps: Enabled
  - Auto play next file in folder: Enabled
  
Preferences → Video:
  - Hardware acceleration: Enabled
  - HDR: Enabled (if supported)
  
Preferences → Subtitles:
  - Auto-load subs: Enabled
  - Font size: 40 (adjust to preference)
```

### 7.3 Integration with Jellyfin
```
1. Install Jellyfin iOS/macOS app or use web interface
2. Configure custom playback device: iina:// (optional)
3. Use Jellyfin web interface to launch playback
4. IINA plays Jellyfin streams seamlessly
```

### 7.4 Network Playback
```
Preferences → Network:
  - Allow network access: Enabled
  - Default playback quality: High
  - Cache network streams: Enabled
```

---

## 8. Complete Workflow Example

### 8.1 Daily Media Management Flow

```
1. Download Phase (Torbox)
   └─ Torrents complete → Auto-move to /media/torrents/

2. Processing Phase
   └─ Run manual scan or auto-import script
   └─ Files move to correct library folders

3. Backup Phase (Scheduled at 3 AM)
   ├─ rsync: /media → /external-backup/
   └─ rclone: /media → idrive-e2:media-storage

4. Access Phase
   ├─ Local: iina for direct playback
   ├─ Network: Jellyfin web/app interface
   └─ Remote: VPN + Jellyfin for external access
```

### 8.2 Automated Backup Script
```bash
#!/bin/bash
# ~/scripts/backup-media.sh

LOG_FILE="$HOME/.backup-media.log"
MEDIA_PATH="/path/to/media"
BACKUP_PATH="/backup/drive/media"
IDrive_REMOTE="idrive-e2:media-storage"

echo "[$(date)] Starting media backup..." >> $LOG_FILE

# Local backup
echo "[$(date)] Running rsync backup..." >> $LOG_FILE
rsync -avz --delete --progress \
  "$MEDIA_PATH/" \
  "$BACKUP_PATH/" \
  --exclude='*.tmp' \
  --exclude='.*' >> $LOG_FILE 2>&1

# Cloud backup
echo "[$(date)] Running rclone sync..." >> $LOG_FILE
/usr/local/bin/rclone sync \
  "$MEDIA_PATH" \
  "$IDrive_REMOTE" \
  --progress \
  --exclude='*.tmp' >> $LOG_FILE 2>&1

echo "[$(date)] Backup completed." >> $LOG_FILE
```

### 8.3 Cron Schedule (macOS/Linux)
```bash
# crontab -e

# Backup strategy:
# 3 AM - Local rsync backup
0 3 * * * ~/scripts/backup-media.sh

# 4 AM - IDrive E2 sync
0 4 * * 0 /usr/local/bin/rclone sync /path/to/media idrive-e2:media-storage >> ~/rclone.log 2>&1

# 5 AM - Cleanup old torrent files
0 5 * * * find /path/to/media/torrents -type f -mtime +7 -delete

# 6 AM - Refresh Jellyfin libraries
0 6 * * * curl -X POST http://localhost:8096/Library/Refresh
```

---

## 9. Best Practices & Optimization

### 9.1 Storage Hierarchy
```
Tier 1 (HOT): Local SSD - Recently accessed media
Tier 2 (WARM): External HDD - Archive, backup
Tier 3 (COLD): idrive e2 - Long-term backup, disaster recovery
```

### 9.2 File Organization
```
/media
├── movies/
│   ├── Action/
│   ├── Comedy/
│   └── Drama/
├── tv/
│   ├── Series1/
│   │   ├── S01/
│   │   └── S02/
│   └── Series2/
├── music/
│   ├── Artist1/
│   └── Artist2/
└── torrents/
    └── (auto-cleanup after 7 days)
```

### 9.3 Data Integrity
```bash
# Verify checksums before important syncs
rclone check /local/media idrive-e2:media-storage --one-way

# Generate backup manifest
rclone ls idrive-e2:media-storage -R > ~/backup-manifest.txt

# Compare sizes
rclone du /local/media
rclone du idrive-e2:media-storage
```

### 9.4 Network Optimization
```
Local Network:
  - Jellyfin: Direct playback (no transcoding)
  - Quality: Original or near-original

Remote Access (Over Internet):
  - Jellyfin: Enable transcoding
  - Quality: 720p-1080p adaptive bitrate
  - Bandwidth limit: 5-10 Mbps

IDrive E2 Mount (rclone):
  - Use read-only mode for media
  - Cache frequently accessed metadata
  - Not ideal for real-time playback (use for archive only)
```

### 9.5 Security
```
IDrive E2:
  - Use IAM credentials (not root access key)
  - Enable bucket versioning for recovery
  - Set lifecycle policies for cost control

Jellyfin:
  - Run behind reverse proxy with TLS
  - Use strong authentication
  - Restrict API access to known IPs

Local Storage:
  - Encrypt external backup drives
  - Use RAID or redundancy where possible
```

---

## 10. Troubleshooting & Monitoring

### 10.1 Common Issues

**Rclone Mount Failures**
```bash
# Check logs
rclone rcd --rc-web-gui &
# OR
pkill -f rclone
rclone mount idrive-e2:media-storage ~/mnt/idrive -vv
```

**Jellyfin Library Not Updating**
```bash
# Manual refresh via CLI
curl -X POST http://localhost:8096/Library/Refresh

# Check permissions
ls -la /path/to/media
chmod -R 755 /path/to/media
```

**Rsync Slow Performance**
```bash
# Check network
iperf3 -c destination.ip

# Adjust rsync parameters
rsync -avz --bwlimit=10000 ...  # Limit to 10MB/s

# Use faster compression
rsync -avz --compress-choice=zstd ...
```

### 10.2 Monitoring Script
```bash
#!/bin/bash
# ~/scripts/monitor-backup.sh

echo "Local Media Size:"
du -sh /path/to/media

echo "Backup Drive Size:"
du -sh /backup/drive/media

echo "IDrive E2 Size:"
rclone du idrive-e2:media-storage

echo "Last Sync:"
tail -5 ~/rclone.log

echo "Jellyfin Status:"
curl -s http://localhost:8096/System/Info | jq '.ServerName, .OperatingSystem'
```

---

## 11. Cost Optimization

### 11.1 IDrive E2 Pricing Strategy
```
Standard Storage: $0.015/GB/month
Lifecycle Policy: Move to archive after 90 days (save 60%)
Bandwidth: Outbound costs money, minimize restores
Recommended: ~$50-100/month for 5TB archive
```

### 11.2 Backup Frequency
```
Daily: Small/recent files only
Weekly: Full media library
Monthly: Verify integrity & test restore
```

### 11.3 Retention Policy
```
Local Primary: 1 month active rotation
External Backup: 12 months (2-3 full backups)
Cloud Archive: Indefinite (encrypted, versioned)
```

---

## 12. Quick Start Checklist

- [ ] IDrive E2 bucket created
- [ ] Rclone configured and tested
- [ ] Rclone GUI installed (optional but recommended)
- [ ] Rsync scripts created
- [ ] Torbox configured
- [ ] Jellyfin installed and libraries configured
- [ ] IINA installed (if macOS)
- [ ] Backup scripts created
- [ ] Cron jobs scheduled
- [ ] Monitoring setup
- [ ] Test full restore from backup
- [ ] Document passwords and API keys in password manager

---

## References

- [Rclone Documentation](https://rclone.org/docs/)
- [IDrive E2 S3 Configuration](https://www.idrive.com/e2/api/)
- [Jellyfin Docs](https://jellyfin.org/docs/)
- [Torbox API](https://docs.torbox.app/)
- [IINA Project](https://iina.io/)
- [Rsync Manual](https://linux.die.net/man/1/rsync)


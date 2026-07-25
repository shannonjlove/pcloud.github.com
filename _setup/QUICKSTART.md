---
layout: page
title: Quick Start Guide - Media Server & Backup Setup
permalink: /quickstart/
---

# Quick Start Guide: Complete Media Management Setup

Get your media server, backup, and file management system up and running in 30 minutes.

## Prerequisites

- macOS, Linux, or Windows (with WSL2)
- Docker & Docker Compose (for Jellyfin)
- IDrive E2 account with S3 credentials
- ~5-10GB free disk space minimum

---

## Step 1: Install Required Tools (5 minutes)

### macOS
```bash
# Install Homebrew packages
brew install rclone rsync docker

# Optional: Install GUIs
brew install rclone-ng
```

### Linux (Ubuntu/Debian)
```bash
# Install from repositories
sudo apt update
sudo apt install -y rclone rsync docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Verify Installation
```bash
rclone version
rsync --version
docker --version
docker-compose --version
```

---

## Step 2: Configure IDrive E2 (5 minutes)

### 2.1 Get IDrive E2 Credentials
1. Log in to [IDrive E2](https://www.idrive.com/e2/)
2. Create a new bucket: `media-storage`
3. Generate API credentials:
   - Navigate to: Account Settings → API Keys
   - Create new key pair
   - Copy **Access Key** and **Secret Key**

### 2.2 Configure Rclone
```bash
# Start rclone configuration wizard
rclone config

# When prompted, enter:
# Name: idrive-e2
# Storage type: s3
# Provider: Other
# Access Key: [paste your key]
# Secret Key: [paste your secret]
# Region: us-east-1
# Endpoint: https://s3.e2.wasabisys.com
```

### 2.3 Test Connection
```bash
# Verify connection works
rclone ls idrive-e2:media-storage
# Should return (empty if new bucket): "total size 0"

# Check configuration
rclone config show
```

---

## Step 3: Prepare Local Directories (5 minutes)

```bash
# Create directory structure
mkdir -p ~/Media/movies
mkdir -p ~/Media/tv
mkdir -p ~/Media/music
mkdir -p ~/Media/torrents
mkdir -p ~/.backup-media-logs
mkdir -p /tmp/jellyfin-transcode

# Set proper permissions
chmod 755 ~/Media
chmod 755 ~/Media/*
```

---

## Step 4: Install & Configure Jellyfin (10 minutes)

### Option A: Docker (Recommended)
```bash
# Clone or download docker-compose-jellyfin.yml
# Edit paths in the file to match your setup
nano _docker/docker-compose-jellyfin.yml

# Update these lines:
# - /path/to/media → ~/Media
# - /path/to/jellyfin/config → ~/.jellyfin
# - JELLYFIN_PublishedServerUrl → http://YOUR_IP:8096

# Start Jellyfin
docker-compose -f _docker/docker-compose-jellyfin.yml up -d

# Verify it's running
docker ps | grep jellyfin
```

### Option B: Bare Metal (macOS)
```bash
# Install Jellyfin
brew install jellyfin

# Start service
brew services start jellyfin

# Access at: http://localhost:8096
```

### 4.1 Initial Setup
1. Open http://localhost:8096 in browser
2. Complete initial wizard:
   - Set display name and language
   - Add media library paths:
     - Movies: `~/Media/movies`
     - TV Shows: `~/Media/tv`
     - Music: `~/Media/music`
   - Create initial user account
3. Wait for metadata fetching to complete

### 4.2 Configure Playback Settings
```
Settings → Playback:
  - Transcoding: Enabled
  - Temporary directory: /tmp/jellyfin-transcode
  - Enable subtitles: Yes
```

---

## Step 5: Setup Backup Automation (5 minutes)

### 5.1 Install Backup Script
```bash
# Copy script to ~/scripts
mkdir -p ~/scripts
cp _scripts/backup-media-automation.sh ~/scripts/
chmod +x ~/scripts/backup-media-automation.sh

# Create log directory
mkdir -p ~/.backup-media-logs
```

### 5.2 Test Backup Script
```bash
# Run a test backup (dry-run)
MEDIA_PATH=~/Media BACKUP_PATH=/backup/media \
  ~/scripts/backup-media-automation.sh backup

# Check logs
tail -f ~/.backup-media-logs/*.log
```

### 5.3 Schedule Automated Backups
```bash
# Edit crontab
crontab -e

# Add these lines:
# 3 AM - Local backup
0 3 * * * MEDIA_PATH=~/Media BACKUP_PATH=/backup/media ~/scripts/backup-media-automation.sh backup

# 4 AM - Cloud sync to IDrive E2
0 4 * * 0 /usr/local/bin/rclone sync ~/Media idrive-e2:media-storage --progress

# Save and exit (Ctrl+X, then Y, then Enter)
```

---

## Step 6: Install IINA (macOS Only)

```bash
# Install IINA media player
brew install iina

# Configure for Jellyfin playback:
# 1. Open IINA preferences
# 2. Under General → Auto play next file: Enable
# 3. Video → Hardware acceleration: Enable
# 4. Use Jellyfin web interface to play videos
#    (IINA will handle playback automatically)
```

---

## Step 7: Connect Torbox (Optional)

```bash
# Get Torbox API key from https://www.torbox.app/api

# Configure download location to: ~/Media/torrents/

# Test via API:
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.torbox.app/v1/user

# Files will auto-appear in Jellyfin after scan
```

---

## Step 8: Verify Everything Works

### 8.1 Quick Validation
```bash
# Check rclone connection
rclone lsd idrive-e2:

# Check Jellyfin health
curl http://localhost:8096/System/Ping

# Check backup script
~/scripts/backup-media-automation.sh monitor

# Check cron jobs
crontab -l
```

### 8.2 Test Playback
1. Add test video to `~/Media/movies/`
2. Open Jellyfin web interface
3. Click on the movie and select Play
4. Video should play smoothly

### 8.3 Test Backup
```bash
# Perform manual backup
~/scripts/backup-media-automation.sh backup

# Check IDrive E2
rclone ls idrive-e2:media-storage
```

---

## Common Commands Reference

```bash
# Sync media to IDrive E2
rclone sync ~/Media idrive-e2:media-storage --progress

# Mount IDrive E2 as virtual drive (macOS/Linux)
mkdir -p ~/mnt/idrive
rclone mount idrive-e2:media-storage ~/mnt/idrive --daemon

# Check storage usage
du -sh ~/Media
rclone du idrive-e2:media-storage

# Backup to external drive
rsync -avz --progress ~/Media/ /Volumes/backup-drive/media/

# Run full backup workflow
~/scripts/backup-media-automation.sh backup

# Monitor backup status
~/scripts/backup-media-automation.sh monitor

# Verify backup integrity
~/scripts/backup-media-automation.sh verify

# Restore from backup
~/scripts/backup-media-automation.sh restore /Volumes/backup-drive/media/

# Jellyfin logs
docker logs -f jellyfin
# OR
tail -f ~/.local/share/jellyfin/logs/*
```

---

## Troubleshooting

### Jellyfin not accessible
```bash
# Check if running
docker ps | grep jellyfin

# Restart service
docker-compose restart jellyfin

# Check logs
docker logs jellyfin
```

### Rclone sync fails
```bash
# Test connectivity
rclone lsd idrive-e2:

# Check configuration
rclone config show

# Run with verbose output
rclone sync ~/Media idrive-e2:media-storage -vv
```

### Backup script errors
```bash
# Check permissions
ls -la ~/scripts/backup-media-automation.sh
chmod +x ~/scripts/backup-media-automation.sh

# Run with debug output
bash -x ~/scripts/backup-media-automation.sh backup

# Check logs
tail -50 ~/.backup-media-logs/backup-*.log
```

### Cron jobs not running
```bash
# Verify cron is running
ps aux | grep cron

# Check system logs
# macOS: log stream --predicate 'process == "cron"'
# Linux: tail -f /var/log/syslog | grep CRON

# Test cron command directly
0 3 * * * ~/scripts/backup-media-automation.sh backup
# Run it now: ~/scripts/backup-media-automation.sh backup
```

---

## Next Steps

1. **Organize Media:** Sort files into proper directory structure
2. **Configure Jellyfin:** Adjust playback settings and transcoding
3. **Setup Remote Access:** Use reverse proxy (Nginx/Caddy) for external access
4. **Enable Hardware Acceleration:** Configure GPU transcoding if available
5. **Schedule Regular Backups:** Verify automated jobs are running
6. **Monitor Storage:** Track usage and clean up old torrents

---

## Directory Structure Summary

```
~/Media/
├── movies/              # Jellyfin movies library
├── tv/                  # Jellyfin TV shows library
├── music/               # Jellyfin music library
└── torrents/            # Torbox downloads (auto-cleanup)

~/.jellyfin/            # Jellyfin config (Docker)
~/.backup-media-logs/   # Backup logs
~/scripts/              # Custom scripts
~/mnt/idrive/          # Optional: IDrive E2 mount point
/backup/drive/         # External backup location
```

---

## Getting Help

- [Rclone Documentation](https://rclone.org/docs/)
- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [IDrive E2 API Docs](https://www.idrive.com/e2/api/)
- [Torbox API Docs](https://docs.torbox.app/)


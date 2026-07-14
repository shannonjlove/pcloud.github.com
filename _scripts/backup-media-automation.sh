#!/bin/bash

################################################################################
# Media Backup Automation Script
# Purpose: Automated backup workflow for media files
# Usage: ./backup-media-automation.sh [backup|verify|restore|monitor]
#
# This script orchestrates:
# 1. Local rsync backup
# 2. Cloud sync to IDrive E2 via rclone
# 3. Integrity verification
# 4. Cleanup old files
################################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${HOME}/.backup-media-logs"
LOG_FILE="${LOG_DIR}/backup-$(date +%Y%m%d-%H%M%S).log"
CONFIG_FILE="${HOME}/.backup-media.conf"

MEDIA_PATH="${MEDIA_PATH:-/path/to/media}"
BACKUP_PATH="${BACKUP_PATH:-/backup/drive/media}"
IDrive_REMOTE="${IDrive_REMOTE:-idrive-e2:media-storage}"
RCLONE_PROFILE="${RCLONE_PROFILE:-idrive-e2}"

# Create log directory
mkdir -p "$LOG_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Logging Functions
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"
}

################################################################################
# Utility Functions
################################################################################

check_paths() {
    log "Checking required paths..."

    if [ ! -d "$MEDIA_PATH" ]; then
        error "Media path does not exist: $MEDIA_PATH"
        return 1
    fi

    if [ ! -d "$BACKUP_PATH" ]; then
        warning "Backup path does not exist, creating: $BACKUP_PATH"
        mkdir -p "$BACKUP_PATH"
    fi

    success "Path validation passed"
    return 0
}

check_commands() {
    log "Checking required commands..."

    local required_commands=("rsync" "rclone" "du" "find")

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command not found: $cmd"
            return 1
        fi
    done

    success "All required commands are available"
    return 0
}

get_disk_usage() {
    local path="$1"
    du -sh "$path" 2>/dev/null | cut -f1
}

################################################################################
# Backup Functions
################################################################################

backup_local() {
    log "Starting local rsync backup..."

    local start_time=$(date +%s)

    # Perform rsync backup with detailed logging
    if rsync -avz \
        --delete \
        --progress \
        --stats \
        --exclude='*.tmp' \
        --exclude='.*' \
        --exclude='@eaDir' \
        --exclude='Thumbs.db' \
        --timeout=30 \
        "$MEDIA_PATH/" \
        "$BACKUP_PATH/" >> "$LOG_FILE" 2>&1; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Local backup completed in ${duration}s"
        return 0
    else
        error "Local backup failed"
        return 1
    fi
}

backup_cloud() {
    log "Starting IDrive E2 cloud sync..."

    local start_time=$(date +%s)

    # Check IDrive E2 connectivity
    if ! rclone lsd "$RCLONE_PROFILE:" >> "$LOG_FILE" 2>&1; then
        error "Cannot connect to IDrive E2. Verify configuration."
        return 1
    fi

    # Sync to cloud with verification
    if rclone sync \
        "$MEDIA_PATH" \
        "$IDrive_REMOTE" \
        --progress \
        --stats \
        --checksum \
        --exclude='*.tmp' \
        --exclude='.*' \
        -v >> "$LOG_FILE" 2>&1; then

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Cloud sync completed in ${duration}s"
        return 0
    else
        error "Cloud sync failed"
        return 1
    fi
}

################################################################################
# Verification Functions
################################################################################

verify_backup() {
    log "Verifying backup integrity..."

    log "Local media size: $(get_disk_usage "$MEDIA_PATH")"
    log "Backup size: $(get_disk_usage "$BACKUP_PATH")"

    # Compare file counts
    local media_count=$(find "$MEDIA_PATH" -type f | wc -l)
    local backup_count=$(find "$BACKUP_PATH" -type f | wc -l)

    log "Media files: $media_count"
    log "Backup files: $backup_count"

    if [ "$media_count" -eq "$backup_count" ]; then
        success "File count verification passed"
    else
        warning "File count mismatch: media=$media_count, backup=$backup_count"
    fi

    # Check IDrive E2 size
    log "Querying IDrive E2 storage..."
    local cloud_size=$(rclone du "$IDrive_REMOTE" 2>/dev/null | tail -1 | awk '{print $1}')
    if [ -n "$cloud_size" ]; then
        log "IDrive E2 usage: $(numfmt --to=iec $cloud_size 2>/dev/null || echo "$cloud_size bytes")"
    fi
}

verify_checksums() {
    log "Verifying checksums (one-way check)..."

    if rclone check \
        "$MEDIA_PATH" \
        "$IDrive_REMOTE" \
        --one-way \
        --progress \
        -v >> "$LOG_FILE" 2>&1; then
        success "Checksum verification passed"
        return 0
    else
        warning "Checksum verification found differences"
        return 1
    fi
}

################################################################################
# Cleanup Functions
################################################################################

cleanup_old_files() {
    log "Cleaning up old torrent files..."

    local torrent_path="$MEDIA_PATH/torrents"
    local days_old=7

    if [ -d "$torrent_path" ]; then
        log "Removing files older than $days_old days from $torrent_path"

        local deleted_count=$(find "$torrent_path" -type f -mtime +$days_old -delete -print | wc -l)

        if [ "$deleted_count" -gt 0 ]; then
            info "Deleted $deleted_count old files"
        fi
    fi
}

cleanup_cache() {
    log "Cleaning up rclone cache..."

    local cache_dir="${HOME}/.cache/rclone"
    if [ -d "$cache_dir" ]; then
        rm -rf "$cache_dir"
        info "Cleared rclone cache"
    fi
}

################################################################################
# Monitoring Functions
################################################################################

monitor_status() {
    log "=== Media Backup Status ==="

    echo ""
    echo "Local Storage:"
    echo "  Path: $MEDIA_PATH"
    echo "  Size: $(get_disk_usage "$MEDIA_PATH")"
    echo "  Files: $(find "$MEDIA_PATH" -type f | wc -l)"

    echo ""
    echo "Backup Storage:"
    echo "  Path: $BACKUP_PATH"
    echo "  Size: $(get_disk_usage "$BACKUP_PATH")"
    echo "  Files: $(find "$BACKUP_PATH" -type f | wc -l)"

    echo ""
    echo "IDrive E2 Remote:"
    if rclone lsd "$RCLONE_PROFILE:" &>/dev/null; then
        echo "  Status: Connected"
        echo "  Size: $(rclone du "$IDrive_REMOTE" 2>/dev/null | tail -1 | awk '{print $1}')"
    else
        echo "  Status: Disconnected"
    fi

    echo ""
    echo "Recent Logs:"
    tail -10 "$LOG_FILE"

    echo ""
    echo "Last Backups:"
    ls -lh "$LOG_DIR" | tail -5
}

restore_from_backup() {
    log "Starting restore from backup..."

    if [ -z "$1" ]; then
        error "Usage: restore <source_path> <destination_path>"
        return 1
    fi

    local source="$1"
    local destination="${2:-$MEDIA_PATH}"

    warning "This will restore files from $source to $destination"
    read -p "Continue? (yes/no) " -n 3 -r
    echo

    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "Restoring from $source to $destination"

        rsync -avz \
            --progress \
            --stats \
            "$source/" \
            "$destination/" \
            >> "$LOG_FILE" 2>&1

        success "Restore completed"
    else
        info "Restore cancelled"
        return 1
    fi
}

restore_from_cloud() {
    log "Starting restore from IDrive E2..."

    local destination="${1:-$MEDIA_PATH}"

    warning "This will restore files from $IDrive_REMOTE to $destination"
    read -p "Continue? (yes/no) " -n 3 -r
    echo

    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "Restoring from cloud to $destination"

        rclone sync \
            "$IDrive_REMOTE" \
            "$destination" \
            --progress \
            -v >> "$LOG_FILE" 2>&1

        success "Restore completed"
    else
        info "Restore cancelled"
        return 1
    fi
}

################################################################################
# Main Workflow
################################################################################

full_backup() {
    log "=== FULL BACKUP WORKFLOW STARTED ==="

    check_commands || exit 1
    check_paths || exit 1

    backup_local || exit 1
    backup_cloud || exit 1

    cleanup_old_files
    cleanup_cache

    verify_backup
    verify_checksums || warning "Checksums don't match, may need re-sync"

    log "=== FULL BACKUP WORKFLOW COMPLETED ==="
    success "Backup workflow finished successfully"
}

################################################################################
# Usage
################################################################################

usage() {
    cat << EOF
Usage: $(basename "$0") [COMMAND]

Commands:
    backup      Run full backup workflow (local + cloud)
    verify      Verify backup integrity and checksums
    monitor     Display backup status and recent logs
    restore     Restore from local backup
    restore-cloud Restore from IDrive E2
    cleanup     Clean up old files and caches
    help        Display this help message

Environment Variables:
    MEDIA_PATH      Path to media directory (default: /path/to/media)
    BACKUP_PATH     Path to backup directory (default: /backup/drive/media)
    IDrive_REMOTE   IDrive E2 remote name (default: idrive-e2:media-storage)
    RCLONE_PROFILE  Rclone profile to use (default: idrive-e2)

Examples:
    # Full backup
    ./backup-media-automation.sh backup

    # Verify backup
    ./backup-media-automation.sh verify

    # Monitor status
    ./backup-media-automation.sh monitor

    # Restore from local backup
    ./backup-media-automation.sh restore /backup/drive/media

EOF
}

################################################################################
# Main Entry Point
################################################################################

main() {
    case "${1:-backup}" in
        backup)
            full_backup
            ;;
        verify)
            verify_backup
            verify_checksums
            ;;
        monitor)
            monitor_status
            ;;
        restore)
            restore_from_backup "$2"
            ;;
        restore-cloud)
            restore_from_cloud "$2"
            ;;
        cleanup)
            cleanup_old_files
            cleanup_cache
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"

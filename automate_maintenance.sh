#!/bin/bash
# Date: 2026-01-13
# Maintainer: kunal mane <kode.techm@gmail.com>
# Description: Automate backup and cleanup of a specified directory, with logging and Git integration.
# Define configuration variables
SOURCE_DIR="/home/vboxuser/nov-2025/classes" # Directory to back up
BACKUP_DIR="/home/vboxuser/nov-2025/backup"   # Directory to store backups
LOG_FILE="/home/vboxuser/nov-2025/backup-and-cleanup-script/maintenance.log" # Log file path
RETENTION_DAYS=7 # Number of days to retain backups
REPO_PATH="/home/vboxuser/nov-2025/backup-and-cleanup-script" # Path to the Git repository

# Ensure backup and log directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages with timestamps
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- Backup Process ---
log_message "Starting backup process for $SOURCE_DIR"

# Create a timestamped, compressed backup file
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

# Use tar to compress the source directory
tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    log_message "Backup created successfully: $BACKUP_FILE"
else
    log_message "ERROR: Backup creation failed"
    exit 1
fi

# --- Cleanup Process ---
log_message "Starting cleanup process (removing files older than $RETENTION_DAYS days) in $BACKUP_DIR"

# Find and delete files older than the retention period
# -type f: only files
# -mtime +N: modification time older than N days
# -name "*.tar.gz": only target the backup files
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -name "*.tar.gz" -exec rm {} \; 2>> "$LOG_FILE"

log_message "Cleanup process completed"

# --- Git Integration for Incremental Commits ---

cd "$REPO_PATH" || exit

# Stage changes to the log file (and this script if modified)
git add "$LOG_FILE" automate_maintenance.sh

# Check if there are any changes to commit
if ! git diff --cached --quiet; then
    log_message "Committing local changes to Git repository"
    git commit -m "Automated maintenance: Backup run $TIMESTAMP and cleanup" >> "$LOG_FILE" 2>&1
    log_message "Commit successful"
else
    log_message "No new changes to commit in the repository"
fi

log_message "Maintenance script finished"
# End of script

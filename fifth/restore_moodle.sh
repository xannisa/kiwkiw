#!/bin/bash

BACKUP_DIR="/app/se-prac-test/sepractest/db-backups"
PASS="SecretPass123"
DB_NAME="moodle"

usage() {
    echo "Usage: $0 [options]"
    echo "  -h    Display this help message."
    echo "  -l    List all available backup files."
    echo "  (none) Restores the most recent backup found in $BACKUP_DIR"
}

list_backups() {
    echo "Available backups (newest first):"
    ls -1t "$BACKUP_DIR"/*.enc 2>/dev/null
}

restore_latest() {
    LATEST=$(ls -1t "$BACKUP_DIR"/*.enc 2>/dev/null | head -n 1)
    
    if [ -z "$LATEST" ]; then
        echo "Error: No backup files found in $BACKUP_DIR"
        exit 1
    fi

    echo "Restoring from: $LATEST"
    openssl enc -d -aes-256-cbc -pbkdf2 -pass "pass:$PASS" -in "$LATEST" | mysql "$DB_NAME"
    echo "Restore completed successfully."
}

# Parse options
while getopts "hl" opt; do
  case $opt in
    h) usage; exit 0 ;;
    l) list_backups; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# If no arguments are passed, restore the latest
if [ $# -eq 0 ]; then
    restore_latest
fi
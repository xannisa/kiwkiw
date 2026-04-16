#!/bin/bash

# --- Configuration ---
REMOTE_IP="35.162.215.25"
KEY_PATH="privatekey.key" 
DB_NAME="moodle"
DB_USER="sepractest"
BACKUP_DIR="/app/se-prac-test/sepractest/db-backups"
PASS="test"

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

perform_restore() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo "Error: No backup file specified."
        exit 1
    fi

    echo "Establishing secure tunnel to $REMOTE_IP..."
    # Open tunnel on port 3307
    ssh -i "$KEY_PATH" -L 3307:127.0.0.1:3306 sepractest@"$REMOTE_IP" -N -f -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes
    sleep 5

    echo "Decrypting and restoring from: $backup_file"
    # Note: Removed -pbkdf2 for compatibility based on your previous error
    openssl enc -d -aes-256-cbc -pass "pass:$PASS" -in "$backup_file" | \
    mariadb -h 127.0.0.1 -P 3307 --user="$DB_USER" "$DB_NAME"

    # Close tunnel
    pkill -f "ssh -i $KEY_PATH -L 3307:127.0.0.1:3306"
    
    echo "Restore process completed."
}

# --- Argument Parsing ---
while getopts "hl" opt; do
  case $opt in
    h) usage; exit 0 ;;
    l) list_backups; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# Default: Restore latest
if [ $# -eq 0 ]; then
    LATEST=$(ls -1t "$BACKUP_DIR"/*.enc 2>/dev/null | head -n 1)
    if [ -z "$LATEST" ]; then
        echo "Error: No backup files found."
        exit 1
    fi
    perform_restore "$LATEST"
fi
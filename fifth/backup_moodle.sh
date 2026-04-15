#!/bin/bash

# --- Configuration ---
DB_HOST="<REMOTE_VM_IP>"        # The IP of the remote MariaDB VM
DB_USER="sepractest"
DB_NAME="moodle"
BACKUP_DIR="/app/se-prac-test/sepractest/db-backups"
PASS="test"   # Passphrase for file encryption
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTPUT_FILE="$BACKUP_DIR/moodle_backup_$TIMESTAMP.sql.enc"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# --- Backup Execution ---
# Using mariadb-dump for remote extraction
mariadb-dump -h "$DB_HOST" -u "$DB_USER" "$DB_NAME" | \
openssl enc -aes-256-cbc -salt -pbkdf2 -pass "pass:$PASS" -out "$OUTPUT_FILE"

# Enforce ownership and permissions
# Ownership is automatically 'sepractest' as the script runner
chmod 600 "$OUTPUT_FILE"

echo "Database backup encrypted and saved: $OUTPUT_FILE"
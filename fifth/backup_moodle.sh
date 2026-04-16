#!/bin/bash

# --- Configuration ---
REMOTE_IP=<remoteip>
KEY_PATH="privatekey.key" # e.g., /home/sepractest/.ssh/id_rsa
DB_USER="sepractest"
DB_NAME="moodle"
BACKUP_DIR="/app/se-prac-test/sepractest/db-backups"
PASS="test"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTPUT_FILE="$BACKUP_DIR/moodle_backup_$TIMESTAMP.sql.enc"

# --- 1. Establish Temporary SSH Tunnel ---
# This creates a tunnel from local port 3307 to remote 3306
ssh -i "$KEY_PATH" -L 3307:127.0.0.1:3306 sepractest@"$REMOTE_IP" -N -f -o StrictHostKeyChecking=no

# Wait for the tunnel to stabilize
sleep 3

# 2. Backup and Encrypt (Removed -pbkdf2 for compatibility)
# No password flag needed here; it is pulled from ~/.my.cnf
/usr/bin/mariadb-dump --user=root -h 127.0.0.1 -P 3307 "$DB_NAME" | \
/usr/bin/openssl enc -aes-256-cbc -salt -pass "pass:$PASS" -out "$OUTPUT_FILE"
# --- 3. Close Tunnel ---
# Find the specific SSH tunnel process and kill it
pkill -f "ssh -i $KEY_PATH -L 3307:localhost:3306"

# Secure the file
chmod 600 "$OUTPUT_FILE"

echo "Backup completed successfully via SSH Tunnel."
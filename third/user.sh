#!/bin/bash

setup_user_with_key() {
    local USERNAME="sepractest"
    local PRIVATE_KEY="$1"   # path to private key
    local SHELL="/bin/bash"
    local SSH_DIR="/home/$USERNAME/.ssh"
    local AUTH_KEYS="$SSH_DIR/authorized_keys"

    if [ -z "$PRIVATE_KEY" ]; then
        echo "Usage: setup_user_with_key <private_key_path>"
        return 1
    fi

    if [ ! -f "$PRIVATE_KEY" ]; then
        echo "Error: Private key not found!"
        return 1
    fi

    echo "=== Creating user and configuring SSH ==="

    # Create user if not exists
    id "$USERNAME" &>/dev/null || useradd -m -s "$SHELL" "$USERNAME"

    # Create .ssh directory
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    chown "$USERNAME:$USERNAME" "$SSH_DIR"

    # Extract public key from private key
    PUB_KEY=$(ssh-keygen -y -f "$PRIVATE_KEY")

    # Add to authorized_keys (avoid duplicates)
    grep -qxF "$PUB_KEY" "$AUTH_KEYS" 2>/dev/null || echo "$PUB_KEY" >> "$AUTH_KEYS"

    # Set correct permissions
    chmod 600 "$AUTH_KEYS"
    chown "$USERNAME:$USERNAME" "$AUTH_KEYS"

    echo "User $USERNAME created and SSH key installed."

    # remove private key
    sudo rm /home/$USERNAME/.ssh/$USERNAME
}
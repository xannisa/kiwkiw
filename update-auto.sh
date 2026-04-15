#!/bin/bash


update() {
    # Disable all Base repo = Its deprecated centos so I use Vault repo
    # Easiest way is to rename base repo file so it will not detect to yum

    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    # Enable all vault repo
    sed -i s/enabled=0/enabled=1/g /etc/yum.repos.d/CentOS-Vault.repo

    yum repolist
    yum update -y 

    # Update done
}

selinux() {
    local Value="$1"
    # Check SElinux and enabled it to enforcing. default is already ON should be.
    CONFIG_FILE="/etc/selinux/config"

    # Backup config
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

    # Set SELINUX=enforcing
    sed -i 's/^SELINUX=.*/SELINUX=$1/' "$CONFIG_FILE"

    # Apply immediately
    setenforce 1

    # Verify
    echo "Current SELinux mode:"
    getenforce
}

createlogicalvolume (){
    # Create a virtual filesystem
    # use this tutorial https://medium.com/@yhakimi/lvm-how-to-create-and-extend-a-logical-volume-in-linux-9744f27eacfe

    # Install pvcreate command first
    yum install epel-release -y
    yum install lvm2 -y

    # create volume group and logical volume
    DISK="/dev/xvdb"
    VG_NAME="gdplabs"
    LV_NAME="se-prac-test"

    # Create physical volume
    pvcreate $DISK

    # Create volume group
    vgcreate $VG_NAME $DISK

    # Create logical volume using all free space
    lvcreate -l 100%FREE -n $LV_NAME $VG_NAME

    # Create filesystem
    mkfs.ext4 /dev/$VG_NAME/$LV_NAME

}

mountlogicalvolume (){
    
    MOUNT_POINT="/app/se-prac-test"
    # Create mount directory
    mkdir -p $MOUNT_POINT

    # Mount it
    mount /dev/$VG_NAME/$LV_NAME $MOUNT_POINT

    # Persist after reboot (add to fstab)
    echo "/dev/$VG_NAME/$LV_NAME $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab

    # Verify
    echo "==== Verification ===="
    lsblk
    df -h | grep $MOUNT_POINT

    # if it already a filesystem, use this
    # wipefs -a /dev/xvdb
}

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
update
selinux enforcing
createlogicalvolume
mountlogicalvolume
setup_user_with_key 
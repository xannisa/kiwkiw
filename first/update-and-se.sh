#!/bin/bash


update() {
    # Disable all Base repo = Its deprecated centos so I use Vault repo
    # Easiest way is to rename base repo file so it will not detect to yum

    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    
    # Enable all vault repo and add repo for centos version 7(is none)
    sed -i s/enabled=0/enabled=1/g /etc/yum.repos.d/CentOS-Vault.repo

    REPO_FILE="/etc/yum.repos.d/CentOS-Vault.repo"

    echo "Creating $REPO_FILE ..."

    cat <<EOF > "$REPO_FILE"
    #c7
[C7-vault-base]
name=CentOS-7 - Base (Vault)
baseurl=https://vault.centos.org/centos/7/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[C7-vault-updates]
name=CentOS-7 - Updates (Vault)
baseurl=https://vault.centos.org/centos/7/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[C7-vault-extras]
name=CentOS-7 - Extras (Vault)
baseurl=https://vault.centos.org/centos/7/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[C7-vault-centosplus]
name=CentOS-7 - CentOSPlus (Vault)
baseurl=https://vault.centos.org/centos/7/centosplus/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
EOF

    echo "Vault repos added."

    yum clean all
    yum repolist
    yum update -y 

    # Update done
}

selinux() {
    local value="${1:-enforcing}"  # Default to enforcing if none provided
    CONFIG_FILE="/etc/selinux/config"

    # Ensure SELinux is set to enforcing by default
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

    # Update config
    sed -i "s/^SELINUX=.*/SELINUX=${value}/" "$CONFIG_FILE"

    # Apply immediately
    if [ "$value" = "enforcing" ]; then
        setenforce 1
    elif [ "$value" = "permissive" ]; then
        setenforce 0
    fi

    # Verify
    echo "Current SELinux mode:"
    getenforce
}
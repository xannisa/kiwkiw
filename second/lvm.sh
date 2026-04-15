#/bin/bash

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
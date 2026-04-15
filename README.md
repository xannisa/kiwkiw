# kiwkiw

There are 2 Vms, provided IP public for ssh and the default user using private.key.

to ssh to the server use this command. If you ssh from local computer using unix/linux machine, make sure the private key is only read by root by `chmod 600 <privatekeyname.key>`. To ssh use this command :

``` bash
ssh -i <privatekeyfile.key> centos@xx.xx.xx.xx
```

## 1. First thing to do is update and enable enforcing for SElinux

### Yum Update

because the VMs are centos version 7, and the repo is deprecated. Enable from `https://vault.centos.org` repo only for updates. Luckyly, the repo file is already in `/etc/yum.repo.d/CentOS-Vault.repo`. But, need to add one repo for Centos version 7 that is not available in the file. 

The line to add to `/etc/yum.repos.d/CentOS-Vault.repo` is in `update-and-se.sh` file

then enable all vault repo by editing `enabled=1` in that file is the easiest way.

then do :

```bash
sudo yum clean all
sudo yum repolist # if no error then go ahead, if error check again
sudo yum update -y
```

### SElinux enable

Dont forget to use root user by doing `sudo su`
by default, vm is already enforcing. go check with
```bash
getenforce
```

if it produce `Enforcing`, then no need to do.

If the result is other than enforcing, set to enforcing in the config file in `/etc/selinux/config` to make it enable when vm restart or reboot. Update the config to `SELINUX=ENFORCING`. Enforcing will enforce config that outside security matter, it will disable immediattely. There are 3 types of value :
#enforcing - SELinux security policy is enforced.
#permissive - SELinux prints warnings instead of enforcing.
#disabled - No SELinux policy is loaded.

Or if want to one time enable it use 
```bash
setenforce 1
```

## 2. Create logical volume for /dev/xvdb

*Dont forget to use root user by doing `sudo su`*

Based on this site https://medium.com/@yhakimi/lvm-how-to-create-and-extend-a-logical-volume-in-linux-9744f27eacfe, logical volume is more better than the traditional disk partitioning. The storage space for logical volume can be combining from many physical hard drive as if they are part of pool. In this tutorial, one physical hard drive is used for one logical volume just for the used of /app storage.

To check the available volume by using :
``` bash
lsblk
```

If it produce something like this:
```bash
NAME                       MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda                       202:0    0  20G  0 disk 
└─xvda1                    202:1    0  20G  0 part /
xvdb                       202:16   0  20G  0 disk 
```
means it use disk pratitioning and unmounting for disk `xvdb`.

*This needs lvm2 package to install*.
Use this command to install :
``` bash
yum install epel-release -y
yum install lvm2 -y
```

then check it `fdisk -l` then you can see like this:
```bash
Disk /dev/xvdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

without disk identifier, it means `/dev/xvdb` is raw disk and needs to format first. Follow the steps in "format-disk.pdf" file. The important thing for this step is create the disk as Linux LVM system as below example.
```bash
    Device Boot      Start         End      Blocks   Id  System
/dev/xvdb1            2048    41943039    20970496   8e  Linux LVM
```

then, we are ready to create virtual group by use this command :
```bash
    DISK="/dev/xvdb"
    VG_NAME="gdplabs"
    LV_NAME="se-prac-test"

    pvcreate $DISK
    vgcreate $VG_NAME $DISK
    lvcreate -l 100%FREE -n $LV_NAME $VG_NAME # logical volume use all hard drive
    mkfs.ext4 /dev/$VG_NAME/$LV_NAME 
```

Ext4 filesystem type is used for small files usage, and it can shrink if we set up too much space. Then mount it to `/app/se-prac-test` folder. Dont forget to create folder first.

``` bash
    MOUNT_POINT="/app/se-prac-test"
    mkdir -p $MOUNT_POINT
    mount /dev/$VG_NAME/$LV_NAME $MOUNT_POINT
    echo "/dev/$VG_NAME/$LV_NAME $MOUNT_POINT ext4 defaults 0 0" >> /etc/fstab
```

To make auto mount when the system reboot. Write it on `/etc/fstab` file. To check the logical volume use thic command :

```bash
lsblk
```

will produce like this:
```bash
NAME                  MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda                  202:0    0  20G  0 disk 
└─xvda1               202:1    0  20G  0 part /
xvdb                  202:16   0  20G  0 disk 
└─xvdb1               202:17   0  20G  0 part 
  └─gdplabs-se--prac--test
                      253:0    0  20G  0 lvm  /app/se-prac-test
```






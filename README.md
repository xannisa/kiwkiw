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

*This needs lvm2 package to install*
Use this command to install :
``` bash
yum install lvm2 -y
```

then 


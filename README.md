# kiwkiw

**Long Documents**

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

Set the proper date
```bash
sudo timedatectl set-timezone Asia/Jakarta
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

## 3. Create User sepractest

*Dont forget to use root user by doing `sudo su`*

To create a user with shell privilege.

```bash
    id sepractest &>/dev/null || useradd -m -s /bin/bash sepractest
```

This user is used for *still dont know*. Because the privatekey is provided, We need to create publickey for this machine to recognize our privatekey. We need a folder to store it. Commonly, it store on `/home/sepractest/.ssh` folder with name `authorized_key`. To protect from others users, the folder should set to `700` permissions so only the owner can read, write, or go insite the folder and set the folder owner owned by the user. This allow root and the appropriate user to see inside. 


```bash
    mkdir -p /home/sepractest/.ssh
    chmod 700 /home/sepractest/.ssh
    chown sepractest:sepractest /home/sepractest/.ssh
```

then, create the publickey. *dont forget to copy the privatekey file inside to the server, this temporary, and set 700 to it*

```bash
ssh-keygen -y -f <privatekeyfile> > /home/sepractest/.ssh/authorized_key
```

set the permission for `authorized_key` to `600` will only the user and root can change and see.
```bash
    chmod 600 /home/sepractest/.ssh/authorized_key
    chown sepractest:sepractest /home/sepractest/.ssh/authorized_key
```

*Delete the private key on the VM*

Log in into the vm with `sepractest` user and key.

## 4. Install Moodle in VM01

*Dont forget to use root user by doing `sudo su`*

In this VM will install moodle in `/app/se-prac-test/sepractest/moodle` folder. first read the documentation if unfamiliar with moodle. *https://docs.moodle.org/501/en/Installing_Moodle*. Based on the docs, it needs server (nginx), backend (php7x), database (mariadb 10x) and cache-server (redis).

So before it install the others service by using `yum`. Before that, the php74 is used, to install this, it use remi repo. and mariadb 10x is installed by mariadb repo. 

```bash
[mariadb]
name = MariaDB
baseurl = https://mirror.mariadb.org/yum/10.11/centos/7/x86_64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
enabled=1
```
to install remi repo

```bash
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
```

then install all packages , enable those service and start :
```bash
yum install -y mariadb-server redis php php-fpm
systemctl enable nginx mariadb php-fpm redis
systemctl start nginx mariadb php-fpm redis
```

*in the installation later, package checks will perform. we can back it later, ensure the service is running first*

then, locate to `/app/se-prac-test/sepractest/` folder then checkout moodle installation file.
```bash
git clone https://github.com/moodle/moodle.git
#use 39 version
git checkout -t origin/MOODLE_39_STABLE
```

Install git first if no git package.

then, create nginx conf in `/etc/nginx/conf.d/moodle.conf` as web server to pass to php backend file. chnage <domain> to proper domain. Restart the nginx.

then, create php.ini ini `/etc/php.ini` to set some variable values. restart php.

then, can access via website through the domain name in the browser. Follow it, the screenshoot of the step is provided in pdf file.

Will go back to the vm and install the packages
```bash
sudo yum install php-common php-cli php-fpm php-mysqlnd php-zip php-gd php-intl php-mbstring php-xml php-xmlrpc php-soap php-opcache php-json php-curl php-iconv
```
restart php service.

Create the database tables. after installation, `sudo mariadb-secure-installation` to configure the mariadb. And execute this command to create the db and set the unicode required by moodle.

```bash
mariadb -u root -p # type password then
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost' IDENTIFIED BY 'moodle12!';
FLUSH PRIVILEGES;
EXIT;
```

your_password = moodle12!

to solve unicode, add mariadb conf to `/etc/my.cnf` and restart mariadb. And execute this command :
```bash
cd /app/se-prac-test/sepractest/moodle/admin/cli
php admin/cli/mysql_collation.php --collation=utf8mb4_unicode_ci
```

update the tables on db :
```bash
mysqlcheck -u root -p --auto-repair --optimize --all-databases
```

then, update `config.php` in `/app/se-prac-test/sepractest/moodle/config.php` to this
``` bash
<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'localhost';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodleuser';
$CFG->dbpass    = 'moodle12!';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => 3306,
  'dbsocket' => '',
//  'dbcollation' => 'utf8_general_ci', # remove this, I uncomment it
  'dbcollation' => 'utf8mb4_unicode_ci', # ensure the php to db use this unicode
);

$CFG->wwwroot   = 'https://system-qyuwqqtklaufxa.gdplabs.net'; # to redirect to https
$CFG->sslproxy = 1; # add to tell moodle use secure connection
$CFG->dataroot  = '/app/se-prac-test/sepractest/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!

```
restart php-fpm service.

Then, set https using cert from lets encrypt. Install the package to generate cert.
```bash
sudo yum install certbot python2-certbot-nginx -y
```

Then create cert for nginx.
``` bash
sudo certbot --nginx -d <domain>
```

Follow the questions until you get `Congratulations! You have successfully enabled https://<domain>`

Then error from the bwoser because I force to https xD.

Ok, then fill the installation account.


The cache need to configure from website. And the website become no color.

sudo yum install php-opcache

server {
    server_name system-qyuwqqtklaufxa.gdplabs.net;

    root /app/se-prac-test/sepractest/moodle;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/system-qyuwqqtklaufxa.gdplabs.net/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/system-qyuwqqtklaufxa.:qgdplabs.net/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = system-qyuwqqtklaufxa.gdplabs.net) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name system-qyuwqqtklaufxa.gdplabs.net;
    return 404; # managed by Certbot


}

....

long short story, it fails, so I set the `/app/se-prac-test/sepractest/moodle` owned by sepractest but in nginx group.

```bash
sudo usermod -a -G nginx sepractest
```
I want to set all files to owned by sepractest. and I reinstall moodle in `/app/se-prac-test/sepractest/moodle2/moodle` with the same existing config. But the result still no-css for the website.

The redis is not configured bcs the website is broken.


## 5. Create backup

### Backup-DB files

because no access at all from VM2 to VM1 and vice versa then except port 22 (I guess its blocking by external firewall, maybe cloud firewall, security group). So, the idea is used ssh tunnel.

the command in the script `ssh -i "$KEY_PATH" -L 3307:127.0.0.1:3306 sepractest@"$REMOTE_IP" -N -f -o StrictHostKeyChecking=no` is for local forwarding, it means Maps port 3307 on VM02 to port 3306 (MariaDB) on the Remote VM (VM1). The 127.0.0.1 refers to the remote machine's own internal address.

Then `mariadb-dump` is performed to backup the DB. Use openssl is for encyption db-backup.

After backup complete, then kill the ssh tunnel by `pkill -f "ssh -i $KEY_PATH -L 3307:localhost:3306"`

## Restore DB

This script wis written using function to easiest way to determine the requirements. It needs -l and -h options. It requires passing an argument as well.

This restore db use ssh tunnel. then restore the DB using default the latest file backup. After that, will kill the ssh tunnel.

## Crontab to run as sepractest user

This command execute crobtab will execute the `backup_moodle.sh` file with `sepractest` user. It needs to set in crontab config file.

```bash
0 4 * * * sepractest /bin/bash /app/se-prac-test/sepractest/backup_moodle.sh
```

**Attention**

The script still failed because the mariadb-dump. It produce this error `mariadb-dump: Got error: 1045: "Access denied for user 'root'@'localhost' (using password: NO)" when trying to connect`, somehow it happen because the credential for db or grant permission on db still wrong.

The `private.key` is located on `/app/se-prac-test/sepractest` and set to `600` permission. So the user sepractest can run. `db-backups` folder is also set to owned by this user.

The password in file `backup_moodle.sh` and `restore_moodle.sh` is still in plan text :D

*all the .sh files should be running with error, hehe*

## 7. Set up monitoring using Icinga 2 on VM02

the username and password for icinga is :
`admin & adminicinga`

Use this documentation to set up icinga2
https://icinga.com/blog/icinga-2-icinga-web-2-and-director-kickstart-on-centos-7/

```bash
yum install -y https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm
yum install -y epel-release
yum install -y git curl make gcc wget nano vim net-tools tar unzip zip python-devel python-pip python-setuptools
```

and so on.. Please follow the steps until end.
For this step `yum install -y centos-release-scl`

I prefer use Vault repo for `sh-php73` by add 
```bash 
[C7-vault-sclo]
name=CentOS-7 - SCLO (Vault)
baseurl=https://vault.centos.org/centos/7/sclo/\$basearch/rh/
gpgcheck=0
#gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1
```
Because centOs 7 is deprecated so no official repo.

To use https. create the cert using this command :
```bash
yum install -y epel-release
yum install -y certbot python2-certbot-apache

```

it blocked by selinux so apply this command to allow httpd connect to network
```bash
setsebool -P httpd_can_network_connect 1
```

to force to https, install the package `yum install -y certbot python2-certbot-apache` and edit file `/etc/httpd/conf.d/icinga.conf`
with :
```bash
<VirtualHost *:80>
    ServerName <domain>

    DocumentRoot "/usr/share/icingaweb2/public"

    <Directory "/usr/share/icingaweb2/public">
        Options SymLinksIfOwnerMatch
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/icinga_error.log
    CustomLog /var/log/httpd/icinga_access.log combined
</VirtualHost>
```
then restart httpd

then, execute this `certbot --apache -d <domain>`
agree what's necessary only!

Then check on website.

To check the item monitoring. Needs to install icinga2 on VM01 for the agent.

install icinga2, then start and enable it.
then execute `icinga2 node wizard` on both server. Specify VM02 as master and VM01 as agent.

This is the configuration on VM01.
```bash
Please specify if this is an agent/satellite setup ('n' installs a master setup) [Y/n]: y

Starting the Agent/Satellite setup routine...

Please specify the common name (CN) [ip-172-30-2-18.us-west-2.compute.internal]: vm01

Please specify the parent endpoint(s) (master or satellite) where this node should connect to:
Master/Satellite Common Name (CN from your master/satellite node): vm02

Do you want to establish a connection to the parent node from this node? [Y/n]: y
Please specify the master/satellite connection information:
Master/Satellite endpoint host (IP address or FQDN): 184.34.134.89
Master/Satellite endpoint port [5665]: 

Add more master/satellite endpoints? [y/N]: n
```

and this is the configuration from VM02 :
```bash
Please specify the common name (CN) [ip-172-30-2-221.us-west-2.compute.internal]: vm02
Reconfiguring Icinga...
Checking for existing certificates for common name 'vm02'...
Certificates not yet generated. Running 'api setup' now.
Generating master configuration for Icinga 2.
'api' feature already enabled.

Master zone name [master]: 

Default global zones: global-templates director-global
Do you want to specify additional global zones? [y/N]: y

Please specify the name of the global Zone: masterzone

Do you want to specify another global zone? [y/N]: n
Please specify the API bind host/port (optional):
Bind Host []: 
Bind Port []: 

Do you want to disable the inclusion of the conf.d directory [Y/n]: n

Done.

Now restart your Icinga 2 daemon to finish the installation!
```

**Current status**
Monitoring backend 'icinga' is not running. on icingaweb because I accidentally delete the ca-cert in master vm. after i can run `icinga2 node wizard` and configure to run the service, the issue keep persist. I guess the issue come from connection to ido_mysql db. 
1. Already check the connection to the db `mysql -u icinga -p icinga -e "SHOW TABLES;"` : OK
2. COnfiguration file in `/etc/icinga2/features-enabled/ido-mysql.conf` : SAME CREDENTIALS

Then, the connetion from VM01 (host) is failed bcs the master is not listen on 5565 port. I guess the cause is installation setup is not preperly. or blocking by external firewall (cloud maybe).

...no time to continue debugging.
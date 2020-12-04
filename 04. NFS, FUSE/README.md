# Ход работы
Подготавливаем Vagrantfile, MultiMachine с обновлением пакетов и установкой epel-release. Файл в GitHub
## Настройка сервера **NFS**:
Для реализации нам потребуется пакет `nfs-utils`  
Проверим установку пакета с системе:  
`yum info nfs-utils`
<details>
<summary>Вывод</summary>

```Bash
root@nfss ~# yum info nfs-utils
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.yandex.ru
 * epel: ftp.lysator.liu.se
 * extras: mirror.sale-dedic.com
 * updates: mirror.sale-dedic.com
Installed Packages
Name        : nfs-utils
Arch        : x86_64
Epoch       : 1
Version     : 1.3.0
Release     : 0.68.el7
Size        : 1.1 M
Repo        : installed
From repo   : base
Summary     : NFS utilities and supporting clients and daemons for the kernel NFS server
URL         : http://sourceforge.net/projects/nfs
License     : MIT and GPLv2 and GPLv2+ and BSD
Description : The nfs-utils package provides a daemon for the kernel NFS server and
            : related tools, which provides a much higher level of performance than the
            : traditional Linux NFS server used by most users.
            :
            : This package also contains the showmount program.  Showmount queries the
            : mount daemon on a remote host for information about the NFS (Network File
            : System) server on the remote host.  For example, showmount can display the
            : clients which are mounted on that host.
            :
            : This package also contains the mount.nfs and umount.nfs program.

root@nfss ~#
```
</details>

Служба `NFS` установлена в системе.

### Настроим firewall
При настройке будем использовать утилиту `firewall-cmd`  
Определим необходимые порты для открытия. Так как будем использовать **NFSv3** нам потребуются открыть порты для трех служб:
- NFSv3
- rpc-bind
- mountd  

Найдем используемые порты службами NFS: `grep nfs /etc/services`
<details>
<summary>Вывод</summary>

```Bash
root@nfss ~# grep nfs /etc/services
nfs             2049/tcp        nfsd shilp      # Network File System
nfs             2049/udp        nfsd shilp      # Network File System
nfs             2049/sctp       nfsd shilp      # Network File System
netconfsoaphttp 832/tcp                 # NETCONF for SOAP over HTTPS
netconfsoaphttp 832/udp                 # NETCONF for SOAP over HTTPS
netconfsoapbeep 833/tcp                 # NETCONF for SOAP over BEEP
netconfsoapbeep 833/udp                 # NETCONF for SOAP over BEEP
nfsd-keepalive  1110/udp                # Client status info
picknfs         1598/tcp                # picknfs
picknfs         1598/udp                # picknfs
shiva_confsrvr  1651/tcp   shiva-confsrvr   # shiva_confsrvr
shiva_confsrvr  1651/udp   shiva-confsrvr   # shiva_confsrvr
3d-nfsd         2323/tcp                # 3d-nfsd
3d-nfsd         2323/udp                # 3d-nfsd
mediacntrlnfsd  2363/tcp                # Media Central NFSD
mediacntrlnfsd  2363/udp                # Media Central NFSD
winfs           5009/tcp                # Microsoft Windows Filesystem
winfs           5009/udp                # Microsoft Windows Filesystem
enfs            5233/tcp                # Etinnae Network File Service
nfsrdma         20049/tcp               # Network File System (NFS) over RDMA
nfsrdma         20049/udp               # Network File System (NFS) over RDMA
nfsrdma         20049/sctp              # Network File System (NFS) over RDMA
root@nfss ~#
```
</details>  

Список портов служб **NFSv3, NFSv4** указан в таблице ниже:  

Служба | TCP порт  | UDP порт
--|---|--
NFSv3   | 2049   | 2049  
prcbind   |111    | 111
mountd   | 20048  | 20048
NFSv4   | 2049   |    |   |  
nfsrdma  | 20049   | 20049  
nfsd-keepalive |   | 1110
rquotad   |875    |875  


Проверим и откроем необходимые порты на `firewall`  

<details>
<summary> NFS </summary>

```Bash
root@nfss ~# firewall-cmd --permanent --info-service=nfs
nfs
ports: 2049/tcp
protocols:
source-ports:
modules:
destination:
```
</details>

<details>
<summary>rpc-bind</summary>

```bash
root@nfss ~# firewall-cmd --permanent --info-service=rpc-bind
rpc-bind
  ports: 111/tcp 111/udp
  protocols:
  source-ports:
  modules:
  destination:
```
</details>

<details>
<summary>mountd</summary>

```bash
root@nfss ~# firewall-cmd --permanent --info-service=mountd
mountd
  ports: 20048/tcp 20048/udp
  protocols:
  source-ports:
  modules:
  destination:
```
</details>

Служба `NFS` содержит только `TCP-порт`.
<details>
<summary> Посмотрим порты протокола `nfs v3` в `firewall-cmd` </summary>

```Bash
root@nfss ~# firewall-cmd --permanent --info-service=nfs
nfs   nfs3
root@nfss ~# firewall-cmd --permanent --info-service=nfs3
nfs3
  ports: 2049/tcp 2049/udp
  protocols:
  source-ports:
  modules:
  destination:
```
</details>

Подключим в `firewall` службы:  
- NFSv3
- NFSv4
- rpc-bind
- mountd  

```Bash
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=nfs3
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
```
проверим подключенные службы:
```Bash
root@nfss ~# firewall-cmd --permanent --list-all
public
  target: default
  icmp-block-inversion: no
  interfaces:
  sources:
  services: dhcpv6-client mountd nfs nfs3 rpc-bind ssh
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```
Рестартуем фаерволл: `sysyemctl restart firewall-cmd`  
<details>
<summary>Проверим открытые порты</summary>

```Bash
root@nfss ~# ss -tulnp
Netid  State      Recv-Q Send-Q                           Local Address:Port                                          Peer Address:Port
udp    UNCONN     0      0                                    127.0.0.1:969                                                      *:*                   users:(("rpc.statd",pid=793,fd=5))
udp    UNCONN     0      0                                            *:37584                                                    *:*                   users:(("rpc.statd",pid=793,fd=8))
udp    UNCONN     0      0                                            *:989                                                      *:*                   users:(("rpcbind",pid=396,fd=7))
udp    UNCONN     0      0                                192.168.50.10:2049                                                     *:*
udp    UNCONN     0      0                                    127.0.0.1:323                                                      *:*                   users:(("chronyd",pid=377,fd=5))
udp    UNCONN     0      0                                            *:68                                                       *:*                   users:(("dhclient",pid=1825,fd=6))
udp    UNCONN     0      0                                            *:20048                                                    *:*                   users:(("rpc.mountd",pid=804,fd=7))
udp    UNCONN     0      0                                            *:55398                                                    *:*
udp    UNCONN     0      0                                            *:111                                                      *:*                   users:(("rpcbind",pid=396,fd=6))
udp    UNCONN     0      0                                         [::]:47533                                                 [::]:*                   users:(("rpc.statd",pid=793,fd=10))
udp    UNCONN     0      0                                         [::]:989                                                   [::]:*                   users:(("rpcbind",pid=396,fd=10))
udp    UNCONN     0      0                                        [::1]:323                                                   [::]:*                   users:(("chronyd",pid=377,fd=6))
udp    UNCONN     0      0                                         [::]:20048                                                 [::]:*                   users:(("rpc.mountd",pid=804,fd=9))
udp    UNCONN     0      0                                         [::]:111                                                   [::]:*                   users:(("rpcbind",pid=396,fd=9))
udp    UNCONN     0      0                                         [::]:53366                                                 [::]:*
tcp    LISTEN     0      100                                  127.0.0.1:25                                                       *:*                   users:(("master",pid=1040,fd=13))
tcp    LISTEN     0      128                                          *:57274                                                    *:*                   users:(("rpc.statd",pid=793,fd=9))
tcp    LISTEN     0      64                               192.168.50.10:2049                                                     *:*
tcp    LISTEN     0      64                                           *:39210                                                    *:*
tcp    LISTEN     0      128                                          *:111                                                      *:*                   users:(("rpcbind",pid=396,fd=8))
tcp    LISTEN     0      128                                          *:20048                                                    *:*                   users:(("rpc.mountd",pid=804,fd=8))
tcp    LISTEN     0      128                                          *:22                                                       *:*                   users:(("sshd",pid=786,fd=3))
tcp    LISTEN     0      100                                      [::1]:25                                                    [::]:*                   users:(("master",pid=1040,fd=14))
tcp    LISTEN     0      128                                       [::]:44543                                                 [::]:*                   users:(("rpc.statd",pid=793,fd=11))
tcp    LISTEN     0      128                                       [::]:111                                                   [::]:*                   users:(("rpcbind",pid=396,fd=11))
tcp    LISTEN     0      128                                       [::]:20048                                                 [::]:*                   users:(("rpc.mountd",pid=804,fd=10))
tcp    LISTEN     0      64                                        [::]:37555                                                 [::]:*
tcp    LISTEN     0      128                                       [::]:22                                                    [::]:*                   users:(("sshd",pid=786,fd=4))
root@nfss ~#
```
</details>  

Порты открыты, настройка `firewall` завершена  

### Настройка экспорта папок

Определим директорию для общего доступа на сервере **NFS**: /srv/storage:

```bash
mkdir /srv/storage
chown -R nfsnobody:nfsnobody /srv/storage/
chmod -R 777 /srv/storage/

root@nfss ~# ls -l /srv/
total 0
drwxrwxrwx. 2 nfsnobody nfsnobody 49 ноя 15 20:29 storage
root@nfss ~#
```

Настройка экспорта директорий производится в файле: /etc/export. Зададим параметры директории:  
- разрешенная сеть, в нашем случае: 192.168.50.0/24
- rw - чтение, запись
- sync - синхронный режим работы
- root_squash - замещение пользователя root

```bash
root@nfss ~# cat /etc/exports
/srv/storage    192.168.50.0/24(rw,sync,root_squash)
root@nfss ~#
```
Запустим службы NFS

```bash
systemctl enable rpcbind
systemctl enable nfs-server
systemctl start rpcbind nfs-server
```
<details>
<summary> systemctl status rpcbind nfs-server </summary>

```Bash
root@nfss ~# systemctl status rpcbind nfs-server
● rpcbind.service - RPC bind service
   Loaded: loaded (/usr/lib/systemd/system/rpcbind.service; enabled; vendor preset: enabled)
   Active: active (running) since Ср 2020-11-18 05:42:45 UTC; 21h ago
  Process: 359 ExecStart=/sbin/rpcbind -w $RPCBIND_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 378 (rpcbind)
   CGroup: /system.slice/rpcbind.service
           └─378 /sbin/rpcbind -w

ноя 18 05:42:45 nfss systemd[1]: Starting RPC bind service...
ноя 18 05:42:45 nfss systemd[1]: Started RPC bind service.

● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Ср 2020-11-18 05:42:51 UTC; 21h ago
  Process: 813 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 795 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 793 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 795 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

ноя 18 05:42:51 nfss systemd[1]: Starting NFS server and services...
ноя 18 05:42:51 nfss systemd[1]: Started NFS server and services.
root@nfss ~#
```
</details>

Просмотрим экспортируемые директории:

```bash
root@nfss ~# exportfs -av
/srv/storage    192.168.50.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@nfss ~#
```
Директория /srv/storage доступна для хостов из подсети 192.168.50.0/24

Для проверки создадим в расшаренной директории тестовый файл размером 10 Мб
```bash
root@nfss ~# dd if=/dev/zero of=/srv/storage/file1 bs=1M count=10
10+0 records in
10+0 records out
10485760 bytes (10 MB) copied, 0,00618864 s, 1,7 GB/s
root@nfss ~# ls -lah /srv/storage/
total 10M
drwxrwxrwx. 2 nfsnobody nfsnobody  19 ноя 18 06:12 .
drwxr-xr-x. 3 root      root       21 ноя 14 13:20 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
root@nfss ~#
```
На этом этапе настройка NFS-сервера завершена.


## Настройка клиента **NFS**
### Подключение шары командой mount

Посмотрим экспорты с хоста 192.168.50.10:
```bash
[root@nfsc ~]# showmount -e 192.168.50.10
Export list for 192.168.50.10:
/srv/storage 192.168.50.0/24
[root@nfsc ~]#
```
Примонируем директорию NFS в /mnt/nfs-share. Передадим опции -o proto=udp,vers=3, для подключения по протоколу **UDP** и версии **NFSv3**
```bash
[root@nfsc ~]# mkdir /mnt/nfs-share
[root@nfsc ~]# chown -R nfsnobody:nfsnobody /mnt/nfs-share/
[root@nfsc ~]# mount -t nfs -o proto=udp,vers=3 192.168.50.10:/srv/storage /mnt/nfs-share
[root@nfsc ~]# mount |tail -n2
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,seclabel,size=24064k,mode=700,uid=1000,gid=1000)
192.168.50.10:/srv/storage on /mnt/nfs-share type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc ~]#
```
Посмотрим содержимое /mnt/nfs-share:
```bash
[root@nfsc ~]# ls -lah /mnt/nfs-share/
total 10M
drwxrwxrwx. 2 nfsnobody nfsnobody  19 ноя 18 06:12 .
drwxr-xr-x. 3 root      root       23 ноя 18 06:45 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
[root@nfsc ~]#
```
Мы видим примонтированную директорию с созданным ранее файлом.
Создадим файл, размером 15 Мб в подключенной шаре:
```bash
[root@nfsc ~]# dd if=/dev/zero of=/mnt/nfs-share/file2 bs=1M count=15
15+0 records in
15+0 records out
15728640 bytes (16 MB) copied, 0,267917 s, 58,7 MB/s
[root@nfsc ~]# ls -lah /mnt/nfs-share/
total 27M
drwxrwxrwx. 2 nfsnobody nfsnobody  32 ноя 18 07:09 .
drwxr-xr-x. 3 root      root       23 ноя 18 06:45 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
-rw-r--r--. 1 nfsnobody nfsnobody 15M ноя 18 07:09 file2
[root@nfsc ~]#
```
Файл успешно создан с заменой текущего пользователя `root` на `ntfsnobody` по опции root-squash.  
На NFS сервере файл присутствует с тем же владельцем.
```bash
root@nfss ~# ls -lah /srv/storage/
total 27M
drwxrwxrwx. 2 nfsnobody nfsnobody  32 ноя 18 07:09 .
drwxr-xr-x. 3 root      root       21 ноя 14 13:20 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
-rw-r--r--. 1 nfsnobody nfsnobody 15M ноя 18 07:09 file2
root@nfss ~#
```
Подключение шары командой `mount` прошло успешно.
### Подключение шары **AutoFS**

Автомонтирование директории при обращении к ней производится пакетом `autofs`. Проверим его наличие в системе:

<details>
<summary>yum info autofs</summary>

```bash
[root@nfsc ~]# yum info autofs
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                                                                                                           |  21 kB  00:00:00
 * base: mirror.reconn.ru
 * epel: fedora-epel.koyanet.lv
 * extras: ftp.nsc.ru
 * updates: mirror.reconn.ru
base                                                                                                                           | 3.6 kB  00:00:00
epel                                                                                                                           | 4.7 kB  00:00:00
extras                                                                                                                         | 2.9 kB  00:00:00
updates                                                                                                                        | 2.9 kB  00:00:00
(1/3): epel/x86_64/group_gz                                                                                                    |  95 kB  00:00:01
(2/3): epel/x86_64/updateinfo                                                                                                  | 1.0 MB  00:00:04
(3/3): epel/x86_64/primary_db                                                                                                  | 6.9 MB  00:00:10
Available Packages
Name        : autofs
Arch        : x86_64
Epoch       : 1
Version     : 5.0.7
Release     : 113.el7
Size        : 836 k
Repo        : base/7/x86_64
Summary     : A tool for automatically mounting and unmounting filesystems
License     : GPLv2+
Description : autofs is a daemon which automatically mounts filesystems when you use
            : them, and unmounts them later when you are not using them.  This can
            : include network filesystems, CD-ROMs, floppies, and so forth.
```
</details>

Установим пакет: `yum install autofs`

#### Настройка директории автомонтрования NFS.
Определим директорию `/mnt/upload`, как директорию монтирования ФС с сервера NFS:  

Основной файл настроек автомонтирования `/etc/auto.master`, добавим новую точку и карту монтирования в конец файла:

```bash
##### NFS SHARE #####
/mnt     /etc/auto.nfs
```

<details>
<summary>/etc/auto.master</summary>

```Bash
[vagrant@nfsc ~]$ cat /etc/auto.master
#
# Sample auto.master file
# This is a 'master' automounter map and it has the following format:
# mount-point [map-type[,format]:]map [options]
# For details of the format look at auto.master(5).
#
/misc   /etc/auto.misc
#
# NOTE: mounts done from a hosts map will be mounted with the
#       "nosuid" and "nodev" options unless the "suid" and "dev"
#       options are explicitly given.
#
/net    -hosts
#
# Include /etc/auto.master.d/*.autofs
# The included files must conform to the format of this file.
#
+dir:/etc/auto.master.d
#
# Include central master map if it can be found using
# nsswitch sources.
#
# Note that if there are entries for /net or /misc (as
# above) in the included master map any keys that are the
# same will not be seen as the first read key seen takes
# precedence.
#
+auto.master

##### NFS SHARE #####
/mnt    /etc/auto.nfs
[vagrant@nfsc ~]$
```
</details>

Опишем монтируемую директорию в файле карты NFS, `/etc/auto.nfs` и опции автомонтирования NFS шары:

```Bash
[root@nfsc ~]# cat /etc/auto.nfs
upload  -rw,vers=3,proto=udp    192.168.50.10:/srv/storage
[root@nfsc ~]#
```

Посмотрим директорию `/mnt`
```bash
[root@nfsc ~]# ls -la /mnt
total 4
drwxr-xr-x.  2 root root    6 Nov 16 17:51 .
dr-xr-xr-x. 21 root root 4096 Nov 15 20:41 ..
```

<details>
<summary>Запустим службу `autofs` и посмотрим точки монтирования:</summary>

```Bash
[root@nfsc ~]# systemctl restart autofs
[root@nfsc ~]# systemctl status autofs
● autofs.service - Automounts filesystems on demand
   Loaded: loaded (/usr/lib/systemd/system/autofs.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2020-11-16 17:38:57 UTC; 12s ago
 Main PID: 4785 (automount)
   CGroup: /system.slice/autofs.service
           └─4785 /usr/sbin/automount --systemd-service --dont-check-daemon

Nov 16 17:38:57 nfsc systemd[1]: Stopped Automounts filesystems on demand.
Nov 16 17:38:57 nfsc systemd[1]: Starting Automounts filesystems on demand...
Nov 16 17:38:57 nfsc systemd[1]: Started Automounts filesystems on demand.

[root@nfsc ~]# mount | tail -n4
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,seclabel,size=24064k,mode=700,uid=1000,gid=1000)
/etc/auto.misc on /misc type autofs (rw,relatime,fd=5,pgrp=4932,timeout=300,minproto=5,maxproto=5,indirect,pipe_ino=27844)
-hosts on /net type autofs (rw,relatime,fd=11,pgrp=4932,timeout=300,minproto=5,maxproto=5,indirect,pipe_ino=27853)
/etc/auto.nfs on /mnt type autofs (rw,relatime,fd=17,pgrp=4932,timeout=300,minproto=5,maxproto=5,indirect,pipe_ino=27857)
[root@nfsc ~]#
```
</details>

Файловая система не подключена в директорию `/mnt` Посмотрим директорию `/mnt`:
```bash
[root@nfsc ~]# ls -la /mnt
total 4
drwxr-xr-x.  2 root root    0 Nov 16 17:53 .
dr-xr-xr-x. 21 root root 4096 Nov 15 20:41 ..
```
Обратимся к директории `/mnt/upload`:
```bash
[root@nfsc ~]# ls -lah /mnt/upload
total 25M
drwxrwxrwx. 2 nfsnobody nfsnobody  32 ноя 18 07:09 .
drwxr-xr-x. 3 root      root        0 ноя 19 02:56 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
-rw-r--r--. 1 nfsnobody nfsnobody 15M ноя 18 07:09 file2
```
Посмотрим точку монтрования:
```bash
[root@nfsc ~]# mount | tail -n1
192.168.50.10:/srv/storage on /mnt/upload type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc ~]#
```
Директория смонтирована с необходимыми опциями. В частности:
- версия **NFSv3**
- протокол **UDP**

<details>
<summary>Создадим тестовые файлы от пользователя `root` и `vagrant`:</summary>

```bash
[root@nfsc ~]# dd if=/dev/zero of=/mnt/upload/file3 bs=1M count 10
dd: unrecognized operand ‘count’
Try 'dd --help' for more information.
[root@nfsc ~]# dd if=/dev/zero of=/mnt/upload/file3 bs=1M count=10
10+0 records in
10+0 records out
10485760 bytes (10 MB) copied, 0,158121 s, 66,3 MB/s
[root@nfsc ~]# exit
logout
[vagrant@nfsc ~]$ dd if=/dev/zero of=/mnt/upload/file4 bs=1M count=20
20+0 records in
20+0 records out
20971520 bytes (21 MB) copied, 0,337206 s, 62,2 MB/s
[vagrant@nfsc ~]$ ls -lah /mnt/upload/
total 61M
drwxrwxrwx. 2 nfsnobody nfsnobody  58 ноя 19 03:00 .
drwxr-xr-x. 3 root      root        0 ноя 19 02:56 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
-rw-r--r--. 1 nfsnobody nfsnobody 15M ноя 18 07:09 file2
-rw-r--r--. 1 nfsnobody nfsnobody 10M ноя 19 02:58 file3
-rw-rw-r--. 1 vagrant   vagrant   20M ноя 19 03:00 file4
[vagrant@nfsc ~]$
```
</details>

Файлы созданы от определенных в настройках пользователей. Директория подключена.  

На сервере NFS файлы так же присутствуют.
```bash
root@nfss ~# ls -lah /srv/storage/
total 55M
drwxrwxrwx. 2 nfsnobody nfsnobody  58 ноя 19 03:00 .
drwxr-xr-x. 3 root      root       21 ноя 14 13:20 ..
-rw-r--r--. 1 root      root      10M ноя 18 06:12 file1
-rw-r--r--. 1 nfsnobody nfsnobody 15M ноя 18 07:09 file2
-rw-r--r--. 1 nfsnobody nfsnobody 10M ноя 19 02:58 file3
-rw-rw-r--. 1 vagrant   vagrant   20M ноя 19 03:00 file4
root@nfss ~#
```


После таймаута в 5 минут директория автоматически отключается, что уменьшает нагрузку на сервер NFS.

```Bash
[root@nfsc ~]# mount | tail -n4
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,seclabel,size=24064k,mode=700,uid=1000,gid=1000)
/etc/auto.misc on /misc type autofs (rw,relatime,fd=5,pgrp=4932,timeout=300,minproto=5,maxproto=5,indirect,pipe_ino=27844)
-hosts on /net type autofs (rw,relatime,fd=11,pgrp=4932,timeout=300,minproto=5,maxproto=5,indirect,pipe_ino=27853)
/etc/auto.nfs on /mnt type autofs (rw,relatime,fd=17,pgrp=4932,timeout=300,minproto=5,maxproto=5,indirect,pipe_ino=27857)
[root@nfsc ~]#
```
## Заключение

Поставленные задачи выполнены:
- настройка сервера NFS
- настройка файервола для подключения к серверу
- ручное монтирование расшаренной директории по протоколу UDP, используя NFSv3
- автомонтирование расшаренной директории по протоколу UDP, используя NFSv3.

При выполнении задания понравилось:
- выяснение открытия портов файервола
- применение `autofs` для автоматического монтирования директорий
- подготовка Vagrantfile стенда

## Ссылки:

https://ru.wikipedia.org/wiki/Network_File_System
http://linux-nfs.org/wiki/index.php/Main_Page
https://wiki.archlinux.org/index.php/NFS/Troubleshooting
https://www.freebsd.org/doc/ru/books/handbook/network-nis.html
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/ch-nfs
https://wiki.archlinux.org/index.php/Autofs_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)
https://www.youtube.com/watch?v=ETJlRG1WxN8&list=PLU4HoaX9cJ1D5DsOhxgvrHS4ryBdpBD96&index=32

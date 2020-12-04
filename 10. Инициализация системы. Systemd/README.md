# lab8_systemd

## 1. Создание сервиса и юнита
### 1. Создание сервиса `watchlog`  
Проверим наличие файла сервиса `etc/sysconfig/watchlog`
`
```bash
[root@lab8 ~]# ls /etc/sysconfig
anaconda         firewalld         netconsole       rsyncd
authconfig       grub              network          rsyslog
cbq              init              network-scripts  run-parts
chronyd          ip6tables-config  nfs              samba
cloud-info       iptables-config   qemu-ga          selinux
console          irqbalance        rdisc            sshd
cpupower         kernel            readonly-root    wpa_supplicant
crond            man-db            rpcbind
ebtables-config  modules           rpc-rquotad
[root@lab8 ~]#
```
Создадим файл сервиса `/etc/sysconfig/watchlog` и добавим в него данные из методички:
```bash
[root@lab8 ~]# vi /etc/sysconfig/watchlog
# Configuration file for my watchdog service

# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```
Создадим файл лога `/var/log/watchlog.log` и добавим в него данные
```bash
[root@lab8 ~]# echo "ALERT" > /var/log/watchlog.log
[root@lab8 ~]# echo "NOTYFY" >> /var/log/watchlog.log
[root@lab8 ~]# cat /var/log/watchlog.log
ALERT
NOTYFY
[root@lab8 ~]#
```
Проверим, при необходимости создадим скрипт запуска:  
```Bash
[root@lab8 ~]# ll /opt/
total 0
drwxr-xr-x. 9 root root 147 Mar 26 20:26 VBoxGuestAdditions-6.0.18
[root@lab8 ~]#
[root@lab8 ~]# vi /opt/watchlog.sh
#! /bin/bash

WORD=$1
LOG=$2
DATE='date'

if grep $WORD $LOG &> /dev/null
then
   logger "$DATE: I found word, Master!"
else
   exit 0
fi


```
Проверим и при необходимости выдадим права на запуск скрипта:  
```bash
[root@lab8 ~]# ll /opt/
total 4
drwxr-xr-x. 9 root root 147 Mar 26 20:26 VBoxGuestAdditions-6.0.18
-rw-r--r--. 1 root root 140 Mar 29 09:13 watchlog.sh
[root@lab8 ~]# chmod +x /opt/watchlog.sh
[root@lab8 ~]# ll /opt/
total 4
drwxr-xr-x. 9 root root 147 Mar 26 20:26 VBoxGuestAdditions-6.0.18
-rwxr-xr-x. 1 root root 140 Mar 29 09:13 watchlog.sh
```
### 2. Создание юнита
Перейдем в каталог юнитов и просмотрим "Админские" юниты  
```bash
[root@lab8 systemd]# cd /etc/systemd/
[root@lab8 systemd]# ll
total 28
-rw-r--r--.  1 root root  720 Apr 25  2019 bootchart.conf
-rw-r--r--.  1 root root  615 Apr 25  2019 coredump.conf
-rw-r--r--.  1 root root  983 Apr 25  2019 journald.conf
-rw-r--r--.  1 root root  957 Apr 25  2019 logind.conf
drwxr-xr-x. 14 root root 4096 Jun  1  2019 system
-rw-r--r--.  1 root root 1552 Mar 29 09:41 system.conf
drwxr-xr-x.  2 root root    6 Apr 25  2019 user
-rw-r--r--.  1 root root 1127 Apr 25  2019 user.conf
[root@lab8 systemd]# ll system
total 4
drwxr-xr-x. 2 root root   32 Jun  1  2019 basic.target.wants
lrwxrwxrwx. 1 root root   46 Jun  1  2019 dbus-org.freedesktop.NetworkManager.service -> /usr/lib/systemd/system/NetworkManager.service
lrwxrwxrwx. 1 root root   57 Jun  1  2019 dbus-org.freedesktop.nm-dispatcher.service -> /usr/lib/systemd/system/NetworkManager-dispatcher.service
lrwxrwxrwx. 1 root root   37 Jun  1  2019 default.target -> /lib/systemd/system/multi-user.target
drwxr-xr-x. 2 root root   87 Jun  1  2019 default.target.wants
drwxr-xr-x. 2 root root   38 Jun  1  2019 dev-virtio\x2dports-org.qemu.guest_agent.0.device.wants
drwxr-xr-x. 2 root root   32 Jun  1  2019 getty.target.wants
drwxr-xr-x. 2 root root   35 Jun  1  2019 local-fs.target.wants
drwxr-xr-x. 2 root root 4096 Mar 26 20:26 multi-user.target.wants
drwxr-xr-x. 2 root root   48 Jun  1  2019 network-online.target.wants
drwxr-xr-x. 2 root root   31 Jun  1  2019 remote-fs.target.wants
drwxr-xr-x. 2 root root   28 Jun  1  2019 sockets.target.wants
drwxr-xr-x. 2 root root  134 Jun  1  2019 sysinit.target.wants
drwxr-xr-x. 2 root root   44 Jun  1  2019 system-update.target.wants
drwxr-xr-x. 2 root root   29 Jun  1  2019 vmtoolsd.service.requires
[root@lab8 systemd]#
```
Создадим сервис для юнита:
```bash
[root@lab8 systemd]# cd system/
[root@lab8 system]# vi watchlog.service
[Unit]
  Description=My watchlog service
[Service]
  Type=oneshot
  EnvironmentFile=/etc/sysconfig/watchlog
  ExecStart=/opt/watchlog.sh $WORD $LOG
```
Стоит обратить вниманеие на строку запуска: `EnvironmentFile=/etc/sysconfig/`**watchlog**  

Создадим таймер для юнита:
```bash
[root@lab8 system]# vi watchlog.timer
[Unit]
  Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
  OnUnitActiveSec=30
  Unit=watchlog.service
[Install]
  WantedBy=multi-user.target
```
Проверим созданные файлы:  
```bash
[root@lab8 system]# ll
total 12
drwxr-xr-x. 2 root root   32 Jun  1  2019 basic.target.wants
lrwxrwxrwx. 1 root root   46 Jun  1  2019 dbus-org.freedesktop.NetworkManager.service -> /usr/lib/systemd/system/NetworkManager.service
lrwxrwxrwx. 1 root root   57 Jun  1  2019 dbus-org.freedesktop.nm-dispatcher.service -> /usr/lib/systemd/system/NetworkManager-dispatcher.service
lrwxrwxrwx. 1 root root   37 Jun  1  2019 default.target -> /lib/systemd/system/multi-user.target
drwxr-xr-x. 2 root root   87 Jun  1  2019 default.target.wants
drwxr-xr-x. 2 root root   38 Jun  1  2019 dev-virtio\x2dports-org.qemu.guest_agent.0.device.wants
drwxr-xr-x. 2 root root   32 Jun  1  2019 getty.target.wants
drwxr-xr-x. 2 root root   35 Jun  1  2019 local-fs.target.wants
drwxr-xr-x. 2 root root 4096 Mar 26 20:26 multi-user.target.wants
drwxr-xr-x. 2 root root   48 Jun  1  2019 network-online.target.wants
drwxr-xr-x. 2 root root   31 Jun  1  2019 remote-fs.target.wants
drwxr-xr-x. 2 root root   28 Jun  1  2019 sockets.target.wants
drwxr-xr-x. 2 root root  134 Jun  1  2019 sysinit.target.wants
drwxr-xr-x. 2 root root   44 Jun  1  2019 system-update.target.wants
drwxr-xr-x. 2 root root   29 Jun  1  2019 vmtoolsd.service.requires
-rw-r--r--. 1 root root  148 Mar 29 10:00 watchlog.service
-rw-r--r--. 1 root root  171 Mar 29 10:02 watchlog.timer
```
Запустим и проверим созданный юнит:
```bash
[root@lab8 system]# systemctl start watchlog.timer
[root@lab8 system]#
[root@lab8 system]# tail -f /var/log/messages
Mar 29 09:18:26 lab8 systemd: Starting Cleanup of Temporary Directories...
Mar 29 09:18:27 lab8 systemd: Started Cleanup of Temporary Directories.
Mar 29 09:42:14 lab8 systemd: Reloading.
Mar 29 09:42:52 lab8 systemd: Reexecuting.
Mar 29 09:42:52 lab8 systemd: systemd 219 running in system mode. (+PAM +AUDIT +SELINUX +IMA -APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 -SECCOMP +BLKID +ELFUTILS +KMOD +IDN)
Mar 29 09:42:52 lab8 systemd: Detected virtualization kvm.
Mar 29 09:42:52 lab8 systemd: Detected architecture x86-64.
Mar 29 10:01:01 lab8 systemd: Created slice User Slice of root.
Mar 29 10:01:01 lab8 systemd: Started Session 4 of user root.
Mar 29 10:11:11 lab8 systemd: Started Run watchlog script every 30 second.
```
<<<<<<< HEAD
Сервис успешно запущен.
## 2. Изменение юнита сервиса spawn-fcgi  
Установим необходимые пакеты  
```bash
yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
Проверим наличие файла сервиса:
```bash
[root@lab8 ~]# ll /etc/rc.d/init.d/
total 44
-rw-r--r--. 1 root root 18281 Aug 24  2018 functions
-rwxr-xr-x. 1 root root  4569 Aug 24  2018 netconsole
-rwxr-xr-x. 1 root root  7923 Aug 24  2018 network
-rw-r--r--. 1 root root  1160 Apr 25  2019 README
-rwxr-xr-x. 1 root root  2129 Feb  6  2014 spawn-fcgi
[root@lab8 ~]#
```
Раскомментируем строки в файле конфигурации `/etc/sysconfig/spawn-fcgi`:  
```bash
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```
Проверим наличие и добавим юнит сервиса `spawn-fcgi`:
```bash
[root@lab8 ~]# ls /etc/systemd/system/
basic.target.wants                                       network-online.target.wants
dbus-org.freedesktop.NetworkManager.service              remote-fs.target.wants
dbus-org.freedesktop.nm-dispatcher.service               sockets.target.wants
default.target                                           sysinit.target.wants
default.target.wants                                     system-update.target.wants
dev-virtio\x2dports-org.qemu.guest_agent.0.device.wants  vmtoolsd.service.requires
getty.target.wants                                       watchlog.service
local-fs.target.wants                                    watchlog.timer
multi-user.target.wants
[root@lab8 ~]#
[root@lab8 ~]# vi /etc/systemd/system/spawn-fcgi.service
[Unit]
  Description=Spawn-fcgi startup service by Otus
  After=network.target
[Service]
  Type=simple
  PIDFile=/var/run/spawn-fcgi.pid
  EnvironmentFile=/etc/sysconfig/spawn-fcgi
  ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
  KillMode=process
[Install]
  WantedBy=multi-user.target
```
Убедимся в создании юнита:
```bash
[root@lab8 ~]# ls /etc/systemd/system/
basic.target.wants                                       network-online.target.wants
dbus-org.freedesktop.NetworkManager.service              remote-fs.target.wants
dbus-org.freedesktop.nm-dispatcher.service               sockets.target.wants
default.target                                           spawn-fcgi.service
default.target.wants                                     sysinit.target.wants
dev-virtio\x2dports-org.qemu.guest_agent.0.device.wants  system-update.target.wants
getty.target.wants                                       vmtoolsd.service.requires
local-fs.target.wants                                    watchlog.service
multi-user.target.wants                                  watchlog.timer
[root@lab8 ~]#
```
Запустим и проверим работу сервиса `spawn-fcgi`:
```bash
[root@lab8 ~]# systemctl start spawn-fcgi.service
[root@lab8 ~]#  
[root@lab8 ~]# systemctl status spawn-fcgi.service
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-03-29 12:42:21 UTC; 20s ago
 Main PID: 27405 (php-cgi)
    Tasks: 33
   Memory: 13.2M
   CGroup: /system.slice/spawn-fcgi.service
           ├─27405 /usr/bin/php-cgi
           ├─27406 /usr/bin/php-cgi
           ├─27407 /usr/bin/php-cgi
           ├─27408 /usr/bin/php-cgi
           ├─27409 /usr/bin/php-cgi
           ├─27410 /usr/bin/php-cgi
           ├─27411 /usr/bin/php-cgi
           ├─27412 /usr/bin/php-cgi
           ├─27413 /usr/bin/php-cgi
           ├─27414 /usr/bin/php-cgi
           ├─27415 /usr/bin/php-cgi
           ├─27416 /usr/bin/php-cgi
           ├─27417 /usr/bin/php-cgi
           ├─27418 /usr/bin/php-cgi
           ├─27419 /usr/bin/php-cgi
           ├─27420 /usr/bin/php-cgi
           ├─27421 /usr/bin/php-cgi
           ├─27422 /usr/bin/php-cgi
           ├─27423 /usr/bin/php-cgi
           ├─27424 /usr/bin/php-cgi
           ├─27425 /usr/bin/php-cgi
           ├─27426 /usr/bin/php-cgi
           ├─27427 /usr/bin/php-cgi
           ├─27428 /usr/bin/php-cgi
           ├─27429 /usr/bin/php-cgi
           ├─27430 /usr/bin/php-cgi
           ├─27431 /usr/bin/php-cgi
           ├─27432 /usr/bin/php-cgi
           ├─27433 /usr/bin/php-cgi
           ├─27434 /usr/bin/php-cgi
           ├─27435 /usr/bin/php-cgi
           ├─27436 /usr/bin/php-cgi
           └─27437 /usr/bin/php-cgi

Mar 29 12:42:21 lab8 systemd[1]: Started Spawn-fcgi startup service by Otus.
[root@lab8 ~]#
```
Сервис успешно запушен

## 3. Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами

Из документации по httpd: https://www.mankier.com/8/httpd.service#Description-Instantiated_services, для запуска экземпляров сервиса должен быть установлен юнит httpd@.service  

Для этого в `# /etc/systemd/system` выполняем:  
1. `systemctl edit --full httpd`
2. сохраняем без изменений
3. копируем httpd.service в httpd@.service
4. изменняем httpd@.service `systemctl edit --full httpd@`
5. добовляем `EnvironmentFile=/etc/sysconfig/httpd-%i`  
используем %i, так как в файлах `# /etc/sysconfig/httpd-first, httpd-second` используются относительные пути.
6. перезапускаем сулжбы  `systemctl daemon-reload`

Проверяем статус httpd:  
```bash
[root@lab8 conf]# systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-04-12 10:31:20 UTC; 54min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 2342 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/httpd.service
           ├─2342 /usr/sbin/httpd -DFOREGROUND
           ├─2412 /usr/sbin/httpd -DFOREGROUND
           ├─2413 /usr/sbin/httpd -DFOREGROUND
           ├─2414 /usr/sbin/httpd -DFOREGROUND
           ├─2415 /usr/sbin/httpd -DFOREGROUND
           └─2417 /usr/sbin/httpd -DFOREGROUND

Apr 12 10:31:20 lab8 systemd[1]: Starting The Apache HTTP Server...
Apr 12 10:31:20 lab8 httpd[2342]: AH00558: httpd: Could not reliably determine the server's fully...ssage'
Apr 12 10:31:20 lab8 systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@lab8 conf]#
```
В каталоге `# /etc/sysconfig/` скопируем и изменим файл окружения `httpd` как указано в методичке:  
```
# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```
Внесем изменения в конфигурационные файлы `httpd` в директории `/etc/httpd/conf/`  
При открытии портов необходимо уделить внимане SElinux. Проверим список разрешенных портов для httpd:  
```bash
[root@lab8 conf]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
При выборе "не разрешенного" порта экземпляр сервиса не может открыть порт, например для порта 8081:  
```bash
Apr 12 12:19:00 lab8 sudo[3126]: pam_unix(sudo:session): session closed for user root
Apr 12 12:27:35 lab8 polkitd[1246]: Registered Authentication Agent for unix-process:3242:698180 (system bus name :1.39 [/usr/bin/pkttyagent --notify-fd 5 --fallback], object path /org/freedesktop/PolicyKit1/Aut
Apr 12 12:27:35 lab8 systemd[1]: Starting The Apache HTTP Server...
-- Subject: Unit httpd@first.service has begun start-up
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
--
-- Unit httpd@first.service has begun starting up.
Apr 12 12:27:35 lab8 httpd[3248]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1. Set the 'ServerName' directive globally to suppress this message'
Apr 12 12:27:35 lab8 httpd[3248]: (13)Permission denied: AH00072: make_sock: could not bind to address [::]:8081
Apr 12 12:27:35 lab8 httpd[3248]: (13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:8081
Apr 12 12:27:35 lab8 httpd[3248]: no listening sockets available, shutting down
Apr 12 12:27:35 lab8 httpd[3248]: AH00015: Unable to open logs
Apr 12 12:27:35 lab8 systemd[1]: httpd@first.service: main process exited, code=exited, status=1/FAILURE
Apr 12 12:27:35 lab8 systemd[1]: httpd@first.service: control process exited, code=exited status=1
Apr 12 12:27:35 lab8 kill[3249]: kill: cannot find process ""
Apr 12 12:27:35 lab8 systemd[1]: Failed to start The Apache HTTP Server.
-- Subject: Unit httpd@first.service has failed

````  
Скопируем и внесем изменения в файлы конфигурации httpd:  
- first.conf  
`cp httpd.conf first.conf`  
изменим параметры PidFile и Listen  
```
PidFile /var/run/httpd-first.pid
Listen 8118
```
- second.conf:
`cp first.conf second.conf`  
изменим параметры PidFile и Listen  
```
PidFile /var/run/httpd-second.pid
Listen 8080
```  

перезапускаем службы `systemctl daemon-reload`
запускаем созданные экземпляры `httpd@first`,  `httpd@second`  

```bash
[root@lab8 conf]# systemctl start httpd@first
[root@lab8 conf]# systemctl start httpd@second
[root@lab8 conf]# systemctl status httpd@*
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-04-12 12:35:54 UTC; 16s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3321 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
    Tasks: 6
   Memory: 2.8M
   CGroup: /system.slice/system-httpd.slice/httpd@first.service
           ├─3321 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3322 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3323 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3324 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           ├─3325 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND
           └─3326 /usr/sbin/httpd -f conf/first.conf -DFOREGROUND

Apr 12 12:35:54 lab8 systemd[1]: Starting The Apache HTTP Server...
Apr 12 12:35:54 lab8 httpd[3321]: AH00558: httpd: Could not reliably determine the server's fully...ssage'
Apr 12 12:35:54 lab8 systemd[1]: Started The Apache HTTP Server.

● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-04-12 12:36:06 UTC; 4s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3384 (httpd)
   Status: "Processing requests..."
    Tasks: 6
   Memory: 2.8M
   CGroup: /system.slice/system-httpd.slice/httpd@second.service
           ├─3384 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3385 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3386 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3387 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           ├─3388 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND
           └─3389 /usr/sbin/httpd -f conf/second.conf -DFOREGROUND

Apr 12 12:36:06 lab8 systemd[1]: Starting The Apache HTTP Server...
Apr 12 12:36:06 lab8 httpd[3384]: AH00558: httpd: Could not reliably determine the server's fully...ssage'
Apr 12 12:36:06 lab8 systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.
```
Проверим открытые порты
```bash
[root@lab8 conf]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=3389,fd=4),("httpd",pid=3388,fd=4),("httpd",pid=3387,fd=4),("httpd",pid=3386,fd=4),("httpd",pid=3385,fd=4),("httpd",pid=3384,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=2417,fd=4),("httpd",pid=2415,fd=4),("httpd",pid=2414,fd=4),("httpd",pid=2413,fd=4),("httpd",pid=2412,fd=4),("httpd",pid=2342,fd=4))
tcp    LISTEN     0      128      :::8118                 :::*                   users:(("httpd",pid=3326,fd=4),("httpd",pid=3325,fd=4),("httpd",pid=3324,fd=4),("httpd",pid=3323,fd=4),("httpd",pid=3322,fd=4),("httpd",pid=3321,fd=4))

```
Сервис `httpd` и его экземпляры: `httpd@first, httpd@second` запущены.

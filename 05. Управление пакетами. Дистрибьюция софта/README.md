# lab9_rpm_yum
Otus домашнее задание по управлению пакетами

## Подготовка к выполнению задания
Проверяем Vfgrantfile. Раскомментируем строки  
```bash
#          mkdir -p ~root/.ssh
#          cp ~vagrant/.ssh/auth* ~root/.ssh
```
Запускаем ВМ и проверяем установленные пакеты `vagrant up && vagrant ssh`  
напимер:
```bash
[root@centos ~]# yum info createrepo
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.axelname.ru
 * epel: epel.mirror.far.fi
 * extras: mirror.docker.ru
 * updates: mirror.axelname.ru
Installed Packages
Name        : createrepo
Arch        : noarch
Version     : 0.9.9
Release     : 28.el7
Size        : 302 k
Repo        : installed
From repo   : base
Summary     : Creates a common metadata repository
URL         : http://createrepo.baseurl.org/
License     : GPLv2
Description : This utility will generate a common metadata repository from
            : a directory of rpm packages.


```
## Задание: 1. Создать свой RPM пакет
Соберем пакет nginx с поддержкой openssl  
Для начала работы установим следующие пакеты:
 ```bash
yum install -y \
redhat-lsb-core wget rpmdevtools rpm-build yum-utils
 ```
Скачаем и распакуем в корневой директории root `nginx-1.14.1-1.el7_4.ngx.src.rpm`  
```bash
[root@centos ~]# tree rpmbuild/
rpmbuild/
├── SOURCES
│   ├── COPYRIGHT
│   ├── logrotate
│   ├── nginx-1.14.1.tar.gz
│   ├── nginx.check-reload.sh
│   ├── nginx.conf
│   ├── nginx-debug.service
│   ├── nginx-debug.sysconf
│   ├── nginx.init.in
│   ├── nginx.service
│   ├── nginx.suse.logrotate
│   ├── nginx.sysconf
│   ├── nginx.upgrade.sh
│   └── nginx.vh.default.conf
└── SPECS
    └── nginx.spec

2 directories, 14 files
```
Скачаем и распакуем openssl в корневой директории root:  
```bash
[root@packages ~]# wget https://www.openssl.org/source/latest.tar.gz && tar -xvf latest.tar.gz
```
Так как rpm не поддерживает зависимости пакетов разрешим зависимости коммандой: `yum-builddep rpmbuild/SPECS/nginx.spec`  
Внсем изменения в файл `rpmbuild/SPECS/nginx.spec`  в секцию `%build` , необходимо верно указать каталог openssl, в нашем случае **/root/openssl-1.1.1f**  
```bash
%build
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}" \
    --with-openssl=/root/openssl-1.1.1f
```
Соберем пакет коммандой `rpmbuild -bb rpmbuild/SPECS/nginx.spec`  
Результат сборки пакета:  
```bash
...
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.xmijJq
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.14.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.14.1-1.el7_4.ngx.x86_64
+ exit 0
```
Проверим наличие собранного пакета:  
```bash
[root@centos ~]# ll rpmbuild/RPMS/x86_64/
total 4388
-rw-r--r--. 1 root root 2001568 Apr 13 20:28 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2488528 Apr 13 20:28 nginx-debuginfo-1.14.1-1.el7_4.ngx.x86_64.rpm
```
Установим собранный пакет: `yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm`
Запустим и проверим запуск:  
```bash
[root@centos ~]# systemctl start nginx
[root@centos ~]# systemctl status nginx
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2020-04-13 20:38:01 UTC; 7s ago
...
```
## Задание: 2. Создать свой репозиторий и разместить там ранее собранный RPM
Подготовим каталог для размещения репозитория. И скопируем файлы пакетов:
```bash
[root@centos ~]# mkdir /usr/share/nginx/html/repo
[root@centos ~]# cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm\
 /usr/share/nginx/html/repo/


[root@centos ~]# wget \
http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm\
 -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

[root@centos ~]# ll /usr/share/nginx/html/repo/
total 1972
-rw-r--r--. 1 root root 2001568 Apr 13 20:45 nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
-rw-r--r--. 1 root root   14520 Jun 13  2018 percona-release-0.1-6.noarch.rpm
```
Создадим репозиторй, внесем изменения в конфигурацию ngix, проверим доступность файлов по http:
```bash
[root@centos ~]# createrepo /usr/share/nginx/html/repo/
Spawning worker 0 with 2 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete

[root@centos ~]# vi /etc/nginx/conf.d/default.conf

...
location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
    }


[root@centos ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@centos ~]# nginx -s reload
[root@centos ~]#
[root@centos ~]# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body bgcolor="white">
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          13-Apr-2020 20:50                   -
<a href="nginx-1.14.1-1.el7_4.ngx.x86_64.rpm">nginx-1.14.1-1.el7_4.ngx.x86_64.rpm</a>                13-Apr-2020 20:45             2001568
<a href="percona-release-0.1-6.noarch.rpm">percona-release-0.1-6.noarch.rpm</a>                   13-Jun-2018 06:34               14520
</pre><hr></body>
</html>
```
Подключим созданный репозиторий к системе и проверим входящие в него пакеты: Пакет nginx в репозитории otus **ОТСУТСТВУЕТ**
```bash
[root@centos ~]# yum repolist enabled |grep otus
otus                     otus-linux                                            2
[root@centos ~]# yum list |grep otus
percona-release.noarch                      0.1-6                      otus
```
Пакет nginx **ОТСУТСТВУЕТ** в репозитории otus. Разберемся почему yum не определяет пакет nginx-1.14.1-1.el7_4.ngx.x86_64 в репозитории otus:

Проверим наличие пакетов nginx во всех репозиториях:
```bash
[root@centos ~]# yum provides nginx
...
1:nginx-1.14.1-1.el7_4.ngx.x86_64 : High performance web server
Repo        : otus



1:nginx-1.16.1-1.el7.x86_64 : A high performance web server and reverse
                            : proxy server
Repo        : epel



1:nginx-1.14.1-1.el7_4.ngx.x86_64 : High performance web server
Repo        : installed

```
Как мы видим пакет ngix содеоржится в трех рерозиториях с разными версиями:  
- otus - созданный нами
- epel - подключенный расширенный репозиторий
- installed - ?  

Разберемся с рерозиторием installed.

Проверим версию установленного пакета nginx:
```bash
[root@centos ~]# nginx -v
nginx version: nginx/1.14.1
```
Отключим репозиторий otus
```bash
[root@centos ~]# yum-config-manager --disable otus
```
Проверим в каких репозиториях содержится пакет nginx и список подключенных рерозиториев:
```bash
[root@centos ~]# yum provides nginx
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
epel/x86_64/metalink                               |  30 kB     00:00     
 * base: mirror.axelname.ru
 * epel: mirror.nsc.liu.se
 * extras: mirror.docker.ru
 * updates: mirror.axelname.ru
base                                               | 3.6 kB     00:00     
docker-ce-stable                                   | 3.5 kB     00:00     
extras                                             | 2.9 kB     00:00     
updates                                            | 2.9 kB     00:00     
1:nginx-1.16.1-1.el7.x86_64 : A high performance web server and reverse
                            : proxy server
Repo        : epel


1:nginx-1.14.1-1.el7_4.ngx.x86_64 : High performance web server
Repo        : installed

[root@centos ~]# yum repolist enabled
repo id                          repo name                          status
base/7/x86_64                    CentOS-7 - Base                    10,097
docker-ce-stable/x86_64          Docker CE Stable - x86_64              70
extras/7/x86_64                  CentOS-7 - Extras                     341
updates/7/x86_64                 CentOS-7 - Updates                  1,787
repolist: 12,297


[root@centos ~]#
```
Просмотрим пекеты instaled:
```bash
[root@centos ~]# yum list |grep installed
nginx.x86_64                             1:1.14.1-1.el7_4.ngx          installed
nodejs-read-installed.noarch             0.2.4-1.el7                   epel     
```
При поиске в сети выяснилось. installed - пакет или пакеты  установленные вручную, а не из репозитория, подробнее: https://unix.stackexchange.com/questions/228500/yum-info-what-does-repo-installed-mean  
Для верного определения пакета в репозитории otus выполним следующее:
- временно отключим репозиторий epel, для устранения дублирования информации о пакете nginx.
- подключим репозиторй otus
- переустановим пакет nginx
- подключим репозиторй epel
- проверим список пакетов в репозитории otus:

```bash
[root@centos ~]# yum-config-manager --disable epel
[root@centos ~]# yum-config-manager --enable otus
[root@centos ~]# yum reinstall nginx
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.axelname.ru
 * extras: mirror.docker.ru
 * updates: mirror.axelname.ru
otus                                                                                                                           | 2.9 kB  00:00:00     
otus/primary_db                                                                                                                | 3.3 kB  00:00:00     
Resolving Dependencies
--> Running transaction check
---> Package nginx.x86_64 1:1.14.1-1.el7_4.ngx will be reinstalled
--> Finished Dependency Resolution
[root@centos ~]# yum-config-manager --enable epel
[root@centos ~]# yum list |grep otus
nginx.x86_64                                1:1.14.1-1.el7_4.ngx       @otus    
percona-release.noarch                      0.1-6                      otus     

```
Задача решена  yum  **ОПРЕДЕЛЯЕТ** пакет nginx 1.14.1.-1.el7_4 в репозитории otus.

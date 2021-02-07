# Prometheus

## Задача

Разобраться в работе системы мониторинга Prometheus и Grafana.  
Результат - работающая система мониторинга, без настойки уведомлений. Скриншот Grafana.

- Развернуть два хоста:
  - PROMETHIUSev,
  - testHost
- Снимать метрики и отобразить в Grafana
  - Нагрузка ROMETHIUS
  - Нагрузка testHost
  
## Установка PROMETEUSrv

По документации, развернуть сервер Prometheus возможно несколькими вариантами:

- при помощи образа Docker
- при помощи систем автоматизации Ansible, Puppet и др.
- из собранного исполняемого файла

Для понимания работы Prometheus, установим из собранного исполняемого файла

### Первая попытка установки

Скачивание, распаковка и запуск Prometheus c https://prometheus.io/docs/prometheus/latest/getting_started/

<details> <summary> Результат установки по гайду с официального сайта</summary>

```bash
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ls -1
console_libraries
consoles
data
LICENSE
NOTICE
prometheus
prometheus.yml
promtool
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]#
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ./prometheus --config.file=prometheus.yml
level=info ts=2021-02-04T02:42:20.022Z caller=main.go:326 msg="No time or size retention was set so using the default time retention" duration=15d
level=info ts=2021-02-04T02:42:20.023Z caller=main.go:364 msg="Starting Prometheus" version="(version=2.24.1, branch=HEAD, revision=e4487274853c587717006eeda8804e597d120340)"
level=info ts=2021-02-04T02:42:20.023Z caller=main.go:369 build_context="(go=go1.15.6, user=root@0b5231a0de0f, date=20210120-00:09:36)"
level=info ts=2021-02-04T02:42:20.023Z caller=main.go:370 host_details="(Linux 3.10.0-1160.11.1.el7.x86_64 #1 SMP Fri Dec 18 16:34:56 UTC 2020 x86_64 PROMETHEUSrv (none))"
level=info ts=2021-02-04T02:42:20.023Z caller=main.go:371 fd_limits="(soft=1024, hard=4096)"
level=info ts=2021-02-04T02:42:20.023Z caller=main.go:372 vm_limits="(soft=unlimited, hard=unlimited)"
level=info ts=2021-02-04T02:42:20.025Z caller=web.go:530 component=web msg="Start listening for connections" address=0.0.0.0:9090
level=info ts=2021-02-04T02:42:20.027Z caller=main.go:738 msg="Starting TSDB ..."
level=info ts=2021-02-04T02:42:20.036Z caller=tls_config.go:191 component=web msg="TLS is disabled." http2=false
level=info ts=2021-02-04T02:42:20.037Z caller=head.go:645 component=tsdb msg="Replaying on-disk memory mappable chunks if any"
level=info ts=2021-02-04T02:42:20.037Z caller=head.go:659 component=tsdb msg="On-disk memory mappable chunks replay completed" duration=7.701µs
level=info ts=2021-02-04T02:42:20.037Z caller=head.go:665 component=tsdb msg="Replaying WAL, this may take a while"
level=info ts=2021-02-04T02:42:20.041Z caller=head.go:717 component=tsdb msg="WAL segment loaded" segment=0 maxSegment=2
level=info ts=2021-02-04T02:42:20.041Z caller=head.go:717 component=tsdb msg="WAL segment loaded" segment=1 maxSegment=2
level=info ts=2021-02-04T02:42:20.042Z caller=head.go:717 component=tsdb msg="WAL segment loaded" segment=2 maxSegment=2
level=info ts=2021-02-04T02:42:20.042Z caller=head.go:722 component=tsdb msg="WAL replay completed" checkpoint_replay_duration=36.137µs wal_replay_duration=4.651904ms total_replay_duration=4.714019ms
level=info ts=2021-02-04T02:42:20.043Z caller=main.go:758 fs_type=XFS_SUPER_MAGIC
level=info ts=2021-02-04T02:42:20.043Z caller=main.go:761 msg="TSDB started"
level=info ts=2021-02-04T02:42:20.043Z caller=main.go:887 msg="Loading configuration file" filename=prometheus.yml
level=info ts=2021-02-04T02:42:20.044Z caller=main.go:918 msg="Completed loading of configuration file" filename=prometheus.yml totalDuration=756.532µs remote_storage=8.345µs web_handler=557ns query_engine=3.543µs scrape=348.151µs scrape_sd=35.486µs notify=27.04µs notify_sd=10.935µs rules=2.99µs
level=info ts=2021-02-04T02:42:20.044Z caller=main.go:710 msg="Server is ready to receive web requests."
```
</details>

Результат запуска не удовлетворяет. Ошибка синхронизации времени, не удобный запуск програмы. 

Установим синхронизацию времени

### Установка синхронизации времени

Установим пакеты службы NTP: `yum install ntp ntpdate`

 <details><summary>Результат установки и выполнения</summary>

 ```bash
 [root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ntpdate 1.ru.pool.ntp.org
 4 Feb 02:53:03 ntpdate[8666]: adjust time server 62.231.6.98 offset 0.074836 sec
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]#
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ntpdate -qu 1.ru.pool.ntp.org
server 185.209.85.222, stratum 2, offset -0.000488, delay 0.02846
server 62.231.6.98, stratum 1, offset -0.000529, delay 0.03972
server 91.207.136.50, stratum 2, offset -0.000609, delay 0.06609
server 212.13.97.55, stratum 2, offset 0.007316, delay 0.03726
 4 Feb 02:53:45 ntpdate[8671]: adjust time server 62.231.6.98 offset -0.000529 sec
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]#
 ```
 </details>

<details><summary>Запустим NTP и обновим его статус.</summary>

```bash
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# timedatectl set-ntp true
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# timedatectl status
      Local time: Thu 2021-02-04 02:56:32 UTC
  Universal time: Thu 2021-02-04 02:56:32 UTC
        RTC time: Thu 2021-02-04 02:55:38
       Time zone: UTC (UTC, +0000)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ntpdate 1.ru.pool.ntp.org
 4 Feb 02:56:56 ntpdate[8724]: adjust time server 85.21.78.8 offset -0.002303 sec
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]#
```

</details>

Время на сервере синхронизировано. Ошибка синхронизации времени устранена.

### Установка и настройка Prometheus

Воспользуемся гайдом по установке с https://www.fosslinux.com/10398/how-to-install-and-configure-prometheus-on-centos-7.htm

Создадим:
- Пользователя prometeus
- Директории `/etc/prometheus`,`/var/lib/prometheus`
- Зададим пользователя на директории
- Скопируем данные из скачанного бинарного приложения

<details><summary>Выполнение</summary>

```bash
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# useradd --no-create-home --shell /bin/false prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# mkdir /etc/prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# mkdir /var/lib/prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown prometheus:prometheus /etc/prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown prometheus:prometheus /var/lib/prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ls
console_libraries  consoles  data  LICENSE  NOTICE  prometheus  prometheus.yml  promtool
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# cp prometheus /usr/local/bin/
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# cp promtool /usr/local/bin/
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown prometheus:prometheus /usr/local/bin/prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown prometheus:prometheus /usr/local/bin/promtool
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# cp -r consoles /etc/prometheus/
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# cp -r console_libraries/ /etc/prometheus/
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown -R prometheus:prometheus /etc/prometheus/consoles
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown -R prometheus:prometheus /etc/prometheus/console_libraries/
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# cp prometheus.yml /etc/prometheus/
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# chown prometheus:prometheus /etc/prometheus/prometheus.yml
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# ls -lah /etc/prometheus/
total 16K
drwxr-xr-x.  4 prometheus prometheus   69 Feb  7 06:42 .
drwxr-xr-x. 81 root       root       8.0K Feb  7 06:34 ..
drwxr-xr-x.  2 prometheus prometheus   38 Feb  7 06:40 console_libraries
drwxr-xr-x.  2 prometheus prometheus  173 Feb  7 06:40 consoles
-rw-r--r--.  1 prometheus prometheus  926 Feb  7 06:42 prometheus.yml
```

</details>

Создадим юнит `systemd` для `prometheus`

vim /etc/systemd/system/prometheus.service

```bash
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
```

<details><summary>Перезапустим systemd и запустим prometheus.service</summary>

```bash
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# systemctl daemon-reload
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# systemctl start prometheus
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# systemctl status prometheus
● prometheus.service - Prometheus
   Loaded: loaded (/etc/systemd/system/prometheus.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2021-02-07 06:56:40 UTC; 51s ago
 Main PID: 12509 (prometheus)
   CGroup: /system.slice/prometheus.service
           └─12509 /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc...

Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.164Z caller=head.go:659 component=tsdb msg="On-disk memory mappable chunks replay completed" duration=7.718µs
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.164Z caller=head.go:665 component=tsdb msg="Replaying WAL, this may take a while"
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.166Z caller=tls_config.go:191 component=web msg="TLS is disabled." http2=false
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.166Z caller=head.go:717 component=tsdb msg="WAL segment loaded" segment=0 maxSegment=0
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.166Z caller=head.go:722 component=tsdb msg="WAL replay completed" checkpoint_replay_duration=24.912µs wal_replay…ation=2.285432ms
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.169Z caller=main.go:758 fs_type=XFS_SUPER_MAGIC
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.169Z caller=main.go:761 msg="TSDB started"
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.169Z caller=main.go:887 msg="Loading configuration file" filename=/etc/prometheus/prometheus.yml
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.176Z caller=main.go:918 msg="Completed loading of configuration file" filename=/etc/prometheus/prometheus.yml totalDuration=6.…µs
Feb 07 06:56:41 PROMETHEUSrv prometheus[12509]: level=info ts=2021-02-07T06:56:41.176Z caller=main.go:710 msg="Server is ready to receive web requests."
Hint: Some lines were ellipsized, use -l to show in full.
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]#
```

</details>

Юнит успешно стартовал. Подключимся к web консоли `prometheus`

```bash
[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]# curl localhost:9090/graph
<!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="shortcut icon" href="./favicon.ico"/><meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no"/><meta name="theme-color" content="#000000"/><script>const GLOBAL_CONSOLES_LINK=""</script><link rel="manifest" href="./manifest.json" crossorigin="use-credentials"/><title>Prometheus Time Series Collection and Processing Server</title><link href="./static/css/2.300141ce.chunk.css" rel="stylesheet"><link href="./static/css/main.0b010d50.chunk.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div><script>!function(e){function r(r){for(var n,l,a=r[0],p=r[1],f=r[2],c=0,s=[];c<a.length;c++)l=a[c],Object.prototype.hasOwnProperty.call(o,l)&&o[l]&&s.push(o[l][0]),o[l]=0;for(n in p)Object.prototype.hasOwnProperty.call(p,n)&&(e[n]=p[n]);for(i&&i(r);s.length;)s.shift()();return u.push.apply(u,f||[]),t()}function t(){for(var e,r=0;r<u.length;r++){for(var t=u[r],n=!0,a=1;a<t.length;a++){var p=t[a];0!==o[p]&&(n=!1)}n&&(u.splice(r--,1),e=l(l.s=t[0]))}return e}var n={},o={1:0},u=[];function l(r){if(n[r])return n[r].exports;var t=n[r]={i:r,l:!1,exports:{}};return e[r].call(t.exports,t,t.exports,l),t.l=!0,t.exports}l.m=e,l.c=n,l.d=function(e,r,t){l.o(e,r)||Object.defineProperty(e,r,{enumerable:!0,get:t})},l.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},l.t=function(e,r){if(1&r&&(e=l(e)),8&r)return e;if(4&r&&"object"==typeof e&&e&&e.__esModule)return e;var t=Object.create(null);if(l.r(t),Object.defineProperty(t,"default",{enumerable:!0,value:e}),2&r&&"string"!=typeof e)for(var n in e)l.d(t,n,function(r){return e[r]}.bind(null,n));return t},l.n=function(e){var r=e&&e.__esModule?function(){return e.default}:function(){return e};return l.d(r,"a",r),r},l.o=function(e,r){return Object.prototype.hasOwnProperty.call(e,r)},l.p="./";var a=this.webpackJsonpgraph=this.webpackJsonpgraph||[],p=a.push.bind(a);a.push=r,a=a.slice();for(var f=0;f<a.length;f++)r(a[f]);var i=p;t()}([])</script><script src="./static/js/2.14ef932b.chunk.js"></script><script src="./static/js/main.63f15779.chunk.js"></script></body></html>[root@PROMETHEUSrv prometheus-2.24.1.linux-amd64]#
```
![](pictutes/prometheus_01.png)

Проверим таргеты, за которыми ведем наблюдение:

![](pictutes/prometheus_02.png)

Для получения метрик с сервера `PROMETHEUSrv` установим и настроим Node Exporter

Скачаем крайнюю версию `Node Exporter`

```bash
[root@PROMETHEUSrv opt]# wget https://github.com/prometheus/node_exporter/releases/download/v1.1.0/node_exporter-1.1.0.linux-amd64.tar.gz
[root@PROMETHEUSrv opt]# tar xvfz node_exporter-1.1.0.linux-amd64.tar.gz
```

Создадим: 

- Пользователя
- Перенесем бинарник в `/usr/local/bin`

<details><summary>Выполнение</summary>

```bash
[root@PROMETHEUSrv opt]# useradd -rs /bin/fasle nodeusr
[root@PROMETHEUSrv opt]# ls
node_exporter-1.1.0.linux-amd64  node_exporter-1.1.0.linux-amd64.tar.gz  prometheus-2.24.1.linux-amd64  VBoxGuestAdditions-6.1.16
[root@PROMETHEUSrv opt]# ls node_exporter-1.1.0.linux-amd64
LICENSE  node_exporter  NOTICE
[root@PROMETHEUSrv opt]# mv node_exporter-1.1.0.linux-amd64/node_exporter /usr/local/bin/
```
</details>

Создадим юнит `systemd` для `node_exporter` 

```bash
vim /etc/systemd/system/node_exporter.service

[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nodeusr
Group=nodeusr
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```

<details><summary>Перезапустим systemd и запустим node_exporter.service</summary>

```bash
[root@PROMETHEUSrv opt]# systemctl daemon-reload
[root@PROMETHEUSrv opt]# systemctl start node_exporter
[root@PROMETHEUSrv opt]# systemctl status node_exporter
● node_exporter.service - Node Exporter
   Loaded: loaded (/etc/systemd/system/node_exporter.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2021-02-07 07:48:48 UTC; 5s ago
 Main PID: 12833 (node_exporter)
   CGroup: /system.slice/node_exporter.service
           └─12833 /usr/local/bin/node_exporter

Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=thermal_zone
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=time
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=timex
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=udp_queues
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=uname
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=vmstat
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=xfs
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:113 collector=zfs
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=node_exporter.go:195 msg="Listening on" address=:9100
Feb 07 07:48:48 PROMETHEUSrv node_exporter[12833]: level=info ts=2021-02-07T07:48:48.223Z caller=tls_config.go:191 msg="TLS is disabled." http2=false
[root@PROMETHEUSrv opt]#
[root@PROMETHEUSrv opt]# systemctl enable node_exporter
Created symlink from /etc/systemd/system/multi-user.target.wants/node_exporter.service to /etc/systemd/system/node_exporter.service.
[root@PROMETHEUSrv opt]#
```
</details>


Результат запуска `node_exporter` посмотрим в web консоли
Доступные таргеты
![](pictutes/node_exporter_01.png)

Метрики снимаемые с помощью `node_exporter` смотрим на странице `http://192.168.11.101:9090/metrics
![](pictutes/node_exporter_02.png)

Посмотрим одну из метрик в Prometeus
![](pictutes/node_exporter_03.png)

**Prometeus и получение метрик на `PROMETHEUSrv` настроено**

### Установка и настройка Grafana

Для установки `Grafana` воспользуемся инструкцией с https://grafana.com/docs/grafana/latest/installation/rpm/

Добавим репозиторий grafana oss
```bash
vim /etc/yum.repos.d/grafana.repo

[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
```

Устанновим `grafana`

```bash
yum install grafana -y
```

<details><summary>Запустим `grafana` при помощи `systemd`</summary>

```bash
[root@PROMETHEUSrv opt]# systemctl daemon-reload
[root@PROMETHEUSrv opt]# systemctl start grafana
Failed to start grafana.service: Unit not found.
[root@PROMETHEUSrv opt]# systemctl start grafana-server
[root@PROMETHEUSrv opt]# systemctl status grafana-server
● grafana-server.service - Grafana instance
   Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2021-02-07 09:00:08 UTC; 8s ago
     Docs: http://docs.grafana.org
 Main PID: 13277 (grafana-server)
   CGroup: /system.slice/grafana-server.service
           └─13277 /usr/sbin/grafana-server --config=/etc/grafana/grafana.ini --pidfile=/var/run/grafana/grafana-server.pid --packaging=rpm cfg:default.paths.logs=/var/log/grafana cfg:default.paths.data=/var/...

Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Executing migration" logger=migrator id="add unique index cache_data.cache_key"
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Executing migration" logger=migrator id="create short_url table v1"
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Executing migration" logger=migrator id="add index short_url.org_id-uid"
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Created default admin" logger=sqlstore user=admin
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Created default organization" logger=sqlstore
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Starting plugin search" logger=plugins
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="Registering plugin" logger=plugins id=input
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="External plugins directory created" logger=plugins directory=/var/lib/grafana/plugins
Feb 07 09:00:08 PROMETHEUSrv systemd[1]: Started Grafana instance.
Feb 07 09:00:08 PROMETHEUSrv grafana-server[13277]: t=2021-02-07T09:00:08+0000 lvl=info msg="HTTP Server Listen" logger=http.server address=[::]:3000 protocol=http subUrl= socket=
[root@PROMETHEUSrv opt]# systemctl enable grafana-server
Created symlink from /etc/systemd/system/multi-user.target.wants/grafana-server.service to /usr/lib/systemd/system/grafana-server.service.
[root@PROMETHEUSrv opt]#
```

</details>

Подключимся к web консоли `http:\\192.168.11.101:3000`
![](pictutes/grafana_01.png)

Настроим отображение метрик на дашбордах grafana

Дашбрды различных систем подключаюися при помощи плагинов. После перехода на https://grafana.com/grafana/plugins/prometheus/installation мы видим, что плагин prometheus уже установлен.
![](pictutes/grafana_02.png)

Настроим дашборды метрик сервера `PROMETHEUSrv`. Для получения нагрузки на сервер, создадим файл 10-30 Gb командой `dd`  
Результат нагрузки видим на графиках:
![](pictutes/grafana_03.png)
![](pictutes/grafana_04.png)

Grafana для отображения метрик `prometheus` настроена.

## Установка testHost

Развернем ВМ testHost, ip 192.168.11.102

Для получения метрик с `testHost`, добваим секцию в файл `/etc/prometheus/prometheus.yaml`  
При перезапуске `prometheus` сервис не стратовал. причина краха один и тот же порт `node_exporter`  
Изменим порт в файле конфигурациции:

```yaml
  # Node exporter testHost
  - job_name: 'node_exporter_testHost'
    scrape_interval: 5s
    static_configs:
      - targets: ['192.168.11.102:9101']
```

<details><summary> Перезапустим сервис </summary>

```bash
[root@PROMETHEUSrv opt]# systemctl restart prometheus.service
[root@PROMETHEUSrv opt]# systemctl status prometheus.service
● prometheus.service - Prometheus
   Loaded: loaded (/etc/systemd/system/prometheus.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2021-02-07 10:39:45 UTC; 4s ago
 Main PID: 15258 (prometheus)
   CGroup: /system.slice/prometheus.service
           └─15258 /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storag...

Feb 07 10:39:45 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:45.996Z caller=h...t=3
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.136Z caller=h...t=3
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.212Z caller=h...t=3
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.212Z caller=h...t=3
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.212Z caller=h…614ms
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.215Z caller=m...GIC
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.215Z caller=m...ed"
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.215Z caller=m...yml
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.218Z caller=main…µs
Feb 07 10:39:46 PROMETHEUSrv prometheus[15258]: level=info ts=2021-02-07T10:39:46.218Z caller=m...s."
Hint: Some lines were ellipsized, use -l to show in full.
[root@PROMETHEUSrv opt]#
```

</details>

Посмотрим таргеты в web консоли
![](pictutes/prometheus_node_exp_01.png)

Получаем ошибку подключения к `testHost` на порту 9101.

<details><summary> Установим node_exporter на testHost, аналогично установке на PROMETEUSrv</summary>

```bash
[root@testHost ~]# useradd -rs /bin/fasle nodeusr
[root@testHost ~]# wget https://github.com/prometheus/node_exporter/releases/download/v1.1.0/node_exporter-1.1.0.linux-amd64.tar.gz && tar xvfz node_exporter-1.1.0.linux-amd64.tar.gz
--2021-02-07 10:44:59--  https://github.com/prometheus/node_exporter/releases/download/v1.1.0/node_exporter-1.1.0.linux-amd64.tar.gz
Resolving github.com (github.com)... 140.82.121.3
Connecting to github.com (github.com)|140.82.121.3|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://github-releases.githubusercontent.com/9524057/8d56b480-680f-11eb-8e55-fe3095a2f3fc?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20210207%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210207T104500Z&X-Amz-Expires=300&X-Amz-Signature=150c90880d81e2e8dc3b652c8190ffd746b4ccc38175c56f4bf4074463da3a88&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=9524057&response-content-disposition=attachment%3B%20filename%3Dnode_exporter-1.1.0.linux-amd64.tar.gz&response-content-type=application%2Foctet-stream [following]
--2021-02-07 10:45:00--  https://github-releases.githubusercontent.com/9524057/8d56b480-680f-11eb-8e55-fe3095a2f3fc?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20210207%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210207T104500Z&X-Amz-Expires=300&X-Amz-Signature=150c90880d81e2e8dc3b652c8190ffd746b4ccc38175c56f4bf4074463da3a88&X-Amz-SignedHeaders=host&actor_id=0&key_id=0&repo_id=9524057&response-content-disposition=attachment%3B%20filename%3Dnode_exporter-1.1.0.linux-amd64.tar.gz&response-content-type=application%2Foctet-stream
Resolving github-releases.githubusercontent.com (github-releases.githubusercontent.com)... 185.199.110.154, 185.199.109.154, 185.199.111.154, ...
Connecting to github-releases.githubusercontent.com (github-releases.githubusercontent.com)|185.199.110.154|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 9238000 (8.8M) [application/octet-stream]
Saving to: ‘node_exporter-1.1.0.linux-amd64.tar.gz’

100%[===================================================================>] 9,238,000   4.54MB/s   in 1.9s

2021-02-07 10:45:02 (4.54 MB/s) - ‘node_exporter-1.1.0.linux-amd64.tar.gz’ saved [9238000/9238000]

node_exporter-1.1.0.linux-amd64/
node_exporter-1.1.0.linux-amd64/LICENSE
node_exporter-1.1.0.linux-amd64/NOTICE
node_exporter-1.1.0.linux-amd64/node_exporter
[root@testHost ~]# ls
anaconda-ks.cfg  node_exporter-1.1.0.linux-amd64  node_exporter-1.1.0.linux-amd64.tar.gz  original-ks.cfg
[root@testHost ~]# mv node_exporter-1.1.0.linux-amd64/node_exporter /usr/local/bin/
[root@testHost ~]#
```

</details>

Для изменения порта со стандартного 9100 на 9101 в юнит добваим следующее: ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9101

```bash
[root@testHost ~]# vim /etc/systemd/system/node_exporter.service

[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nodeusr
Group=nodeusr
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9101

[Install]
WantedBy=multi-user.target
```

<details><summary>Перечитаем systemd и запустим юнит node_exporter, проверим порт</summary>

```bash
[root@testHost ~]# systemctl daemon-reload
[root@testHost ~]# systemctl restart node_exporter.service
[root@testHost ~]# systemctl status node_exporter.service
● node_exporter.service - Node Exporter
   Loaded: loaded (/etc/systemd/system/node_exporter.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2021-02-07 10:58:31 UTC; 3s ago
 Main PID: 14309 (node_exporter)
   CGroup: /system.slice/node_exporter.service
           └─14309 /usr/local/bin/node_exporter --web.listen-address=:9101

Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=time
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=timex
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=udp_queues
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=uname
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=vmstat
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=xfs
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:113 collector=zfs
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=node_exporter.go:195 msg="Listening on"...s=:9101
Feb 07 10:58:31 testHost node_exporter[14309]: level=info ts=2021-02-07T10:58:31.672Z caller=tls_config.go:191 msg="TLS is disabled....2=false
Feb 07 10:58:32 testHost node_exporter[14309]: level=error ts=2021-02-07T10:58:32.821Z caller=collector.go:161 msg="collector failed...or cpu"
Hint: Some lines were ellipsized, use -l to show in full.
[root@testHost ~]#
[root@testHost ~]# ss -tlnp
State      Recv-Q Send-Q                          Local Address:Port                                         Peer Address:Port
LISTEN     0      128                                         *:111                                                     *:*                   users:(("rpcbind",pid=368,fd=8))
LISTEN     0      128                                         *:22                                                      *:*                   users:(("sshd",pid=676,fd=3))
LISTEN     0      100                                 127.0.0.1:25                                                      *:*                   users:(("master",pid=876,fd=13))
LISTEN     0      128                                      [::]:9101                                                 [::]:*                   users:(("node_exporter",pid=14309,fd=3))
LISTEN     0      128                                      [::]:111                                                  [::]:*                   users:(("rpcbind",pid=368,fd=11))
LISTEN     0      128                                      [::]:22                                                   [::]:*                   users:(("sshd",pid=676,fd=4))
LISTEN     0      100                                     [::1]:25                                                   [::]:*                   users:(("master",pid=876,fd=14))
[root@testHost ~]#
```
</details>

`node_exporter` запущен на 9101 порту. Страница таргетов это подтверждает.
![](pictutes/prometheus_node_exp_02.png)

Для получения нагрузки на сервер, создадим файл 10-30 Gb командой `dd`  
Результат нагрузки видим на графике:
![](pictutes/testHost_01.png)

Дашборд `grafana` совместил данные с обоих таргетов. Хостов PROMETEUSrv и testHost. Для разделения дашборбов по таргетам можно либо фильтровать метрики в дашборде. Или переписать снимаемые метрики по таргетам.

Шаблон дашборда Prometheus также показал общие графики.
![](pictutes/Grafana_Prometheus_template.png)

**Считаю, что поставленная цель достигнута**  
Prometheus отслеживает состояние двух серверов. Grafana строит графики. Далее можно улучшить отображение графиков, настройку и отсылку алертов.
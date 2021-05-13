# Сбор и анализ логов

## Домашнее задание

Настраиваем центральный сервер для сбора логов
в вагранте поднимаем 2 машины web и log 
на web поднимаем nginx
на log настраиваем центральный лог сервер на любой системе на выбор
- journald
- rsyslog
- elk
настраиваем аудит следящий за изменением конфигов нжинкса

все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита должны также уходить на удаленную систему

* развернуть еще машину elk
и таким образом настроить 2 центральных лог системы elk И какую либо еще
в elk должны уходить только логи нжинкса
во вторую систему все остальное
Критерии оценки: 4 - если присылают только логи скриншоты без вагранта
5 - за полную настройку
6 - если выполнено задание со звездочкой

## Подготовка стенда

Для данного задания будем использовать провижининг в Ansible. Для этого:

- установим `ansible` на хосотвую машину

  ```bash
  ╭─dkasyan@dkasyan-ThinkPad-X240 /mnt/dkasyan/OTUS2020-10/22. Сбор и анализ логов ‹main*›
  ╰─$ ansible --version
  ansible 2.9.9
    config file = /etc/ansible/ansible.cfg
    configured module search path = ['/home/dkasyan/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    ansible python module location = /usr/lib/python3/dist-packages/ansible
    executable location = /usr/bin/ansible
    python version = 3.8.6 (default, Sep 25 2020, 09:36:53) [GCC 10.2.0]
  ```

- подготовим конфигурацию Vagrantfile

  ```bash
            box.vm.provision "shell", inline: <<-SHELL
             mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
             yum install epel-release\
                         bash-completion-extras\
                         vim-enhanced\
                         wget -y
  # Внесем изменения в конфигурацию sshd
             sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' \
             /etc/ssh/sshd_config
  # Перезапустим sshd
             systemctl restart sshd
            SHELL
  # Добавим провижениниг Ansible
            box.vm.provision "ansible" do |ansible|
              ansible.verbose = "vv"
  # Укажем путь к playbook.yaml
              ansible.playbook = "provision/playbook.yaml"
  # Будем исполнять плейбук от root
              ansible.become = "true"
            end
  ```

**ВАЖНО** 
Внимательно настроить структуру репозитория. **Инвентори внутри** Првильно указать параметр: `ansible_private_key_file:` и путь к ключу `/mnt/dkasyan/OTUS2020-10/22. Сбор и анализ логов/.vagrant/machines/LOGSrv/virtualbox/private_key`


- **подготовим файлы для провиженинга ИЗМЕНИТЬ!!!!**
  <details><summary> Вывод </summary>
  
  ```bash
  ╭─dkasyan@dkasyan-ThinkPad-X240 /mnt/dkasyan/OTUS2020-10/22. Сбор и анализ логов ‹main*›
  ╰─$ tree provision
  provision
  ├── ansible.cfg
  ├── inventory
  ├── logsrv
  ├── nginxsrv
  │   └── playbook.yaml
  └── playbook.yaml

  2 directories, 4 files
  ╭─dkasyan@dkasyan-ThinkPad-X240 /mnt/dkasyan/OTUS2020-10/22. Сбор и анализ логов ‹main*›
  ╰─$ cat provision/ansible.cfg
  [defaults]
  inventory = inventory
  remote_user = vagrant
  host_key_checking = False
  retry_files_enabled = False
  ╭─dkasyan@dkasyan-ThinkPad-X240 /mnt/dkasyan/OTUS2020-10/22. Сбор и анализ логов ‹main*›
  ╰─$ cat provision/inventory
  [NGINXSrv]
  NGINXSrv ansible_host=127.0.0.1 ansible_port=2222
  ansible_privite_key=../.vagrant/machines/NGINXSrv/virtualbox/private_key

  ╭─dkasyan@dkasyan-ThinkPad-X240 /mnt/dkasyan/OTUS2020-10/22. Сбор и анализ логов ‹main*›
  ╰─$ cat provision/playbook.yaml
  ---
  - name: NGINXSrv
    hosts: NGINXSrv
    become: true

    tasks:
      - name: Install nginx
        yum:
          name: nginx
          state: latest

        tags:
        - nginx_package
        - packages

      - name: Starting services
        ansible.builtin.systemd:
          name: nginx
          state: started

  #      notify:
  #      - restart nginx
  
  ```
  </details>

## Выполнение задания

В системе линукс имеются системы сбора и удаленное хранения логов:

- rsyslog
- journald

В документации [nginx - Configuring Logging](https://docs.nginx.com/nginx/admin-guide/monitoring/logging/) определяются места хранения логов nginx. Логиррование производится средствами Веб сервера `NGINX` и предсталяют собой текстовые файлы.

Просмотрим конфигурационный файл `/etc/nginx/nginx.conf`, логи собираются в:

```bash
[root@NGINXSrv ~]# less /etc/nginx/nginx.conf
...
error_log /var/log/nginx/error.log;
...
http {
    access_log  /var/log/nginx/access.log  main;
```

```bash
[root@NGINXSrv ~]# ls -la /var/log/nginx/
total 36
drwxrwx---.  2 nginx root  218 Feb 22 03:10 .
drwxr-xr-x. 10 root  root 4096 Feb 21 13:00 ..
-rw-rw-r--.  1 nginx root 2067 Feb 23 07:49 access.log
-rw-r--r--.  1 root  root  280 Feb 14 12:59 access.log-20210215.gz
-rw-rw-r--.  1 nginx root  178 Feb 18 03:12 access.log-20210218.gz
-rw-rw-r--.  1 nginx root  255 Feb 21 13:02 access.log-20210222.gz
-rw-rw-r--.  1 nginx root  652 Feb 23 07:49 error.log
-rw-r--r--.  1 root  root  206 Feb 14 12:25 error.log-20210215.gz
-rw-rw-r--.  1 nginx root  205 Feb 18 03:12 error.log-20210218.gz
-rw-rw-r--.  1 nginx root  205 Feb 21 13:02 error.log-20210222.gz
[root@NGINXSrv ~]# journalctl  -u nginx.service
-- Logs begin at Sun 2021-02-21 12:59:49 UTC, end at Tue 2021-02-23 08:01:01 UTC. --
Feb 21 13:02:11 NGINXSrv systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 21 13:02:11 NGINXSrv nginx[3394]: nginx: the configuration file /etc/nginx/nginx.conf syntax is
Feb 21 13:02:11 NGINXSrv nginx[3394]: nginx: configuration file /etc/nginx/nginx.conf test is succes
Feb 21 13:02:11 NGINXSrv systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Feb 21 13:02:11 NGINXSrv systemd[1]: Started The nginx HTTP and reverse proxy server.
lines 1-6/6 (END)
[root@NGINXSrv ~]#
```

Исходя из этих данных:

- информация из `journalctl` - данные об ошибках сервиса `nginx.service`  
- Основные логи приложения находятся в `/var/log/nginx/`  

Сбор и удаленное хранение логов `nginx` проще организовать используя `rsyslog`  
Для совпадения событий, настроим точное время на хостах:
установим пакет `ntp` и проверим текущее время. Т.к. используем тестовый стенд не будем устанавливать верную таймзону.

<details>
<summary>Настрока на NGINXSrv, на LOGSrv аналогично</summary>

```bash
[root@NGINXSrv ~]# yum install ntp -y
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.axelname.ru
 * epel: fedora-epel.koyanet.lv
 * extras: mirror.axelname.ru
 * updates: mirror.axelname.ru
Resolving Dependencies
--> Running transaction check
---> Package ntp.x86_64 0:4.2.6p5-29.el7.centos.2 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==============================================================================================================================
 Package                Arch                      Version                                       Repository               Size
==============================================================================================================================
Installing:
 ntp                    x86_64                    4.2.6p5-29.el7.centos.2                       base                    549 k

Transaction Summary
==============================================================================================================================
Install  1 Package

Total download size: 549 k
Installed size: 1.4 M
Downloading packages:
ntp-4.2.6p5-29.el7.centos.2.x86_64.rpm                                                                 | 549 kB  00:00:01
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : ntp-4.2.6p5-29.el7.centos.2.x86_64                                                                         1/1
  Verifying  : ntp-4.2.6p5-29.el7.centos.2.x86_64                                                                         1/1

Installed:
  ntp.x86_64 0:4.2.6p5-29.el7.centos.2

Complete!
[root@NGINXSrv ~]# ntptime
ntp_gettime() returns code 0 (OK)
  time e3f0bfc4.84c63ee4  Mon, Mar  8 2021 15:22:44.518, (.518650527),
  maximum error 28958 us, estimated error 218 us, TAI offset 0
ntp_adjtime() returns code 0 (OK)
  modes 0x0 (),
  offset 0.000 us, frequency 6.394 ppm, interval 1 s,
  maximum error 28958 us, estimated error 218 us,
  status 0x2000 (NANO),
  time constant 2, precision 0.001 us, tolerance 500 ppm,
[root@NGINXSrv ~]#
```
</details>

### Настройка NGINXSrv

<details>
<summary>Проверим наличие `rsyslog` в системе и проверим его статус:</summary>

```bash
[root@NGINXSrv ~]# systemctl | grep log
  rhel-dmesg.service                                                                       loaded active exited    Dump dmesg to /var/log/dmesg
  rsyslog.service                                                                          loaded active running   System Logging Service
  systemd-logind.service                                                                   loaded active running   Login Service
[root@NGINXSrv ~]# systemctl status rsyslog.service
● rsyslog.service - System Logging Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2021-03-08 09:42:33 UTC; 17min ago
     Docs: man:rsyslogd(8)
           http://www.rsyslog.com/doc/
 Main PID: 709 (rsyslogd)
   CGroup: /system.slice/rsyslog.service
           └─709 /usr/sbin/rsyslogd -n

Mar 08 09:42:33 NGINXSrv systemd[1]: Starting System Logging Service...
Mar 08 09:42:33 NGINXSrv rsyslogd[709]:  [origin software="rsyslogd" swVersion="8.24.0-52.el7" x-pid="709" x-info... start
Mar 08 09:42:33 NGINXSrv systemd[1]: Started System Logging Service.
Hint: Some lines were ellipsized, use -l to show in full.
[root@NGINXSrv ~]#
[root@NGINXSrv ~]# rsyslogd -v
rsyslogd 8.24.0-52.el7, compiled with:
        PLATFORM:                               x86_64-redhat-linux-gnu
        PLATFORM (lsb_release -d):
        FEATURE_REGEXP:                         Yes
        GSSAPI Kerberos 5 support:              Yes
        FEATURE_DEBUG (debug build, slow code): No
        32bit Atomic operations supported:      Yes
        64bit Atomic operations supported:      Yes
        memory allocator:                       system default
        Runtime Instrumentation (slow code):    No
        uuid support:                           Yes
        Number of Bits in RainerScript integers: 64

See http://www.rsyslog.com for more information.
[root@NGINXSrv ~]#
```
</details>
Rsyslog установлен и запущен

Настройки производим в файле `/etc/rsyslog.conf`

### Настройка LOGSrv

<details>
<summary>Проверим наличие `rsyslog` в системе и проверим его статус:</summary>

```bash
[root@LOGSrv ~]# systemctl | grep log
  rhel-dmesg.service                                                                       loaded active exited    Dump dmesg to /var/log/dmesg
  rsyslog.service                                                                          loaded active running   System Logging Service
  systemd-logind.service                                                                   loaded active running   Login Service
[root@LOGSrv ~]# systemctl status rsyslog.service
● rsyslog.service - System Logging Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2021-03-08 09:42:02 UTC; 29min ago
     Docs: man:rsyslogd(8)
           http://www.rsyslog.com/doc/
 Main PID: 705 (rsyslogd)
   CGroup: /system.slice/rsyslog.service
           └─705 /usr/sbin/rsyslogd -n

Mar 08 09:42:02 LOGSrv rsyslogd[705]:  [origin software="rsyslogd" swVersion="8.24.0-52.el7" x-pid="705" x-info="... start
Mar 08 09:42:02 LOGSrv systemd[1]: Started System Logging Service.
Mar 08 09:42:02 LOGSrv rsyslogd[705]: action 'ModLoad' treated as ':omusrmsg:ModLoad' - please use ':omusrmsg:Mod...2184 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: error during parsing file /etc/rsyslog.conf, on or before line 9: warnings ...2207 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: action 'imuxsock' treated as ':omusrmsg:imuxsock' - please use ':omusrmsg:i...2184 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: error during parsing file /etc/rsyslog.conf, on or before line 9: warnings ...2207 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: warning: ~ action is deprecated, consider using the 'stop' statement instea...2307 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: invalid or yet-unknown config file command 'SystemLogSocketName' - have you...3003 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: invalid or yet-unknown config file command 'OmitLocalLogging' - have you fo...3003 ]
Mar 08 09:42:02 LOGSrv rsyslogd[705]: error during config processing: STOP is followed by unreachable statements!...2207 ]
Hint: Some lines were ellipsized, use -l to show in full.
[root@LOGSrv ~]# rsyslogd -v
rsyslogd 8.24.0-52.el7, compiled with:
        PLATFORM:                               x86_64-redhat-linux-gnu
        PLATFORM (lsb_release -d):
        FEATURE_REGEXP:                         Yes
        GSSAPI Kerberos 5 support:              Yes
        FEATURE_DEBUG (debug build, slow code): No
        32bit Atomic operations supported:      Yes
        64bit Atomic operations supported:      Yes
        memory allocator:                       system default
        Runtime Instrumentation (slow code):    No
        uuid support:                           Yes
        Number of Bits in RainerScript integers: 64

See http://www.rsyslog.com for more information.
[root@LOGSrv ~]#
```
</details>

Rsyslog установлен и запущен

### Конфигурирование `rsyslog` файл `/etc/rsyslog.conf`

Настройки производим в файле `/etc/rsyslog.conf` Настройки различные для сервера и кллиента, но имеют и общие моменты

#### Общие настройки `/etc/rsyslog.conf`

Для работы будем использовать **TCP** соединение, для этого раскомментируем строки:

```bash
# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514
```

Добавим правило разрешающее использование `TCP 514` для `rsyslog` обоих хостах:

```bash
[root@NGINXSrv ~]# semanage port -a -t rsync_port_t -p tcp 514
[root@NGINXSrv ~]# semanage port -l |grep rsync
rsync_port_t                   tcp      514, 873
rsync_port_t                   udp      873
[root@NGINXSrv ~]#
```

```bash
[root@NGINXSrv ~]# firewall-cmd --zone=public --add-port=514/tcp
success

```

```bash
[root@NGINXSrv ~]# grep -v '^$\|^#' /etc/rsyslog.conf
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal
$ModLoad imtcp
$InputTCPServerRun 514
$WorkDirectory /var/lib/rsyslog
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$IncludeConfig /etc/rsyslog.d/*.conf
$OmitLocalLogging on
$IMJournalStateFile imjournal.state
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 :omusrmsg:*
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
[root@NGINXSrv ~]#
```


## ELK
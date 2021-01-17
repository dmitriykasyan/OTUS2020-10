# SELinux

## Цель: Тренируем умение работать с SELinux: диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.

### 1. Запустить nginx на нестандартном порту 3-мя разными способами:  

- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.
К сдаче:
- README с описанием каждого решения (скриншоты и демонстрация приветствуются).

#### Подготовка

Проверим и установим `nginx`:  

```bash
 yum -q nginx
 yum install nginx
```

<details> <summary> Процесс установки и проверки текущих портов nginx </summary>

```bash

[root@SELinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: inactive (dead)

Jan 15 03:12:55 SELinux systemd[1]: Unit nginx.service cannot be reloaded because it is inactive.
[root@SELinux ~]# systemctl enable nginx
Created symlink from /etc/systemd/system/multi-user.target.wants/nginx.service to /usr/lib/systemd/system/nginx.service.
[root@SELinux ~]# systemctl start nginx
[root@SELinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2021-01-15 03:13:46 UTC; 3s ago
  Process: 14965 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 14963 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 14962 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 14967 (nginx)
   CGroup: /system.slice/nginx.service
           ├─14967 nginx: master process /usr/sbin/nginx
           └─14968 nginx: worker process

Jan 15 03:13:46 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 15 03:13:46 SELinux nginx[14963]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 15 03:13:46 SELinux nginx[14963]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 15 03:13:46 SELinux systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jan 15 03:13:46 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@SELinux ~]#
[root@SELinux ~]# ss -tnlp
State      Recv-Q Send-Q                              Local Address:Port                                             Peer Address:Port
LISTEN     0      128                                             *:111                                                         *:*                   users:(("rpcbind",pid=398,fd=8))
LISTEN     0      128                                             *:80                                                          *:*                   users:(("nginx",pid=14968,fd=6),("nginx",pid=14967,fd=6))
LISTEN     0      128                                             *:22                                                          *:*                   users:(("sshd",pid=665,fd=3))
LISTEN     0      100                                     127.0.0.1:25                                                          *:*                   users:(("master",pid=863,fd=13))
LISTEN     0      128                                          [::]:111                                                      [::]:*                   users:(("rpcbind",pid=398,fd=11))
LISTEN     0      128                                          [::]:80                                                       [::]:*                   users:(("nginx",pid=14968,fd=7),("nginx",pid=14967,fd=7))
LISTEN     0      128                                          [::]:22                                                       [::]:*                   users:(("sshd",pid=665,fd=4))
LISTEN     0      100                                         [::1]:25                                                       [::]:*                   users:(("master",pid=863,fd=14))
[root@SELinux ~]#
```
</details>

Nginx установлен и запущен на 80 порту.  
Установим необходимые пакеты для работы с `SELinux`

```bash
yum install setools-console policycoreutils-python policycoreutils-newrole selinux-policy-mls -y
```

#### Выполнение задания:

Проверим режим работы SELinux

```bash
[root@SELinux ~]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31
[root@SELinux ~]#
```

Проверим разрешенные порты http в SELinux:

```bash
[root@SELinux ~]# semanage port -l |grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
[root@SELinux ~]#
```

Для примера будем использовать порт **8088** в качестве порта запуска `nginx`

<details> <summary> Внесем изменения в конфигурационный файл `/etc/nginx/nginx.conf` и перечитаем конфигурацию.</summary>

```bash
    server {
        listen       8088 default_server;
        listen       [::]:8088 default_server;
        server_name  _;
        root         /usr/share/nginx/html;
...
[root@SELinux ~]# vi /etc/nginx/nginx.conf
[root@SELinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@SELinux ~]# ss -tlnp
State      Recv-Q Send-Q                              Local Address:Port                                             Peer Address:Port
LISTEN     0      128                                             *:111                                                         *:*                   users:(("rpcbind",pid=398,fd=8))
LISTEN     0      128                                             *:22                                                          *:*                   users:(("sshd",pid=665,fd=3))
LISTEN     0      100                                     127.0.0.1:25                                                          *:*                   users:(("master",pid=863,fd=13))
LISTEN     0      128                                          [::]:111                                                      [::]:*                   users:(("rpcbind",pid=398,fd=11))
LISTEN     0      128                                          [::]:22                                                       [::]:*                   users:(("sshd",pid=665,fd=4))
LISTEN     0      100                                         [::1]:25                                                       [::]:*                   users:(("master",pid=863,fd=14))
[root@SELinux ~]#
```
</details>

В итоге `nginx` не поднялся на установленном порту 8088.

##### Решение 1 добавление порта в контекст безопасности SELinux.

Воспользуемся утилитой `audit2why`

```bash
[root@SELinux ~]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1610790869.652:1897): avc:  denied  { name_bind } for  pid=8383 comm="nginx" src=8088 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
[root@SELinux ~]#
```

Добавим порт 8088 в контекст безопасности `http_port_t`:

```bash
[root@SELinux ~]# semanage port -a -t http_port_t -p tcp 8088
```
<details><summary> Проверим добавление порта 8088 в контекст безопасности SELinux и работу nginx </summary>

```bash
[root@SELinux ~]# semanage port -l |grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      8088, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
[root@SELinux ~]# systemctl restart nginx
[root@SELinux ~]# ss -tlnp
State      Recv-Q Send-Q                              Local Address:Port                                             Peer Address:Port
LISTEN     0      128                                             *:111                                                         *:*                   users:(("rpcbind",pid=398,fd=8))
LISTEN     0      128                                             *:22                                                          *:*                   users:(("sshd",pid=665,fd=3))
LISTEN     0      128                                             *:8088                                                        *:*                   users:(("nginx",pid=8446,fd=6),("nginx",pid=8445,fd=6))
LISTEN     0      100                                     127.0.0.1:25                                                          *:*                   users:(("master",pid=863,fd=13))
LISTEN     0      128                                          [::]:111                                                      [::]:*                   users:(("rpcbind",pid=398,fd=11))
LISTEN     0      128                                          [::]:22                                                       [::]:*                   users:(("sshd",pid=665,fd=4))
LISTEN     0      128                                          [::]:8088                                                     [::]:*                   users:(("nginx",pid=8446,fd=7),("nginx",pid=8445,fd=7))
LISTEN     0      100                                         [::1]:25                                                       [::]:*                   users:(("master",pid=863,fd=14))
[root@SELinux ~]# ss -tlnp |grep nginx
LISTEN     0      128          *:8088                     *:*                   users:(("nginx",pid=8446,fd=6),("nginx",pid=8445,fd=6))
LISTEN     0      128       [::]:8088                  [::]:*                   users:(("nginx",pid=8446,fd=7),("nginx",pid=8445,fd=7))
[root@SELinux ~]#
```

</details>

Порт добавлен в контекст безопасности SELinux. Nginx запущен на порту 8088.  
**Задача выполнена.**

<details> <summary>Для дальнейшего выполнения задания удалим порт 8088 из контекста безопасности </summary>

```bash
[root@SELinux ~]# semanage port -d -t http_port_t -p tcp 8088
[root@SELinux ~]# semanage port -l |grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
[root@SELinux ~]#
```
</details>

##### Решение 2 формирование и установка модуля SELinux

<details> <summary>Воспользуемся утилитой `sealert` из пакета `setroubleshoot-server`</summary>

```bash
[root@SELinux ~]# yum provides sealert
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos-mirror.rbc.ru
 * epel: mirror.nsc.liu.se
 * extras: mirror.awanti.com
 * updates: mirror.axelname.ru
setroubleshoot-server-3.2.30-8.el7.x86_64 : SELinux troubleshoot server
Repo        : base
Matched from:
Filename    : /usr/bin/sealert



[root@SELinux ~]# rpm -q setroubleshoot-server
package setroubleshoot-server is not installed
[root@SELinux ~]# yum install setroubleshoot-server
...
[root@SELinux ~]# rpm -q setroubleshoot-server
setroubleshoot-server-3.2.30-8.el7.x86_64
[root@SELinux ~]# yum list sealert
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: centos-mirror.rbc.ru
 * epel: mirror.cspacehostings.com
 * extras: mirror.awanti.com
 * updates: mirror.axelname.ru
Error: No matching Packages to list
[root@SELinux ~]#
```

</details>

Воспользуемся командой `sealert -a /var/log/audit/audit.log`

```bash
[root@SELinux ~]# sealert -a /var/log/audit/audit.log
100% done
found 1 alerts in /var/log/audit/audit.log
...
*****  Plugin catchall (1.41 confidence) suggests   **************************

If you believe that nginx should be allowed name_bind access on the port 8088 tcp_socket by default.
Then you should report this as a bug.
You can generate a local policy module to allow this access.
Do
allow this access for now by executing:
# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
# semodule -i my-nginx.pp
```

<details> <summary>Для создания и применения модуля воспользуемся полученными командами ausearch -c 'nginx' --raw | audit2allow -M my-nginx; semodule -i my-nginx.pp: </summary>

```bash
[root@SELinux ~]# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i my-nginx.pp

[root@SELinux ~]# semodule -i my-nginx.pp
[root@SELinux ~]#
[root@SELinux ~]# systemctl restart nginx
[root@SELinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2021-01-16 13:06:26 UTC; 2s ago
  Process: 9334 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 9331 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 9330 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 9336 (nginx)
   CGroup: /system.slice/nginx.service
           ├─9336 nginx: master process /usr/sbin/nginx
           └─9337 nginx: worker process

Jan 16 13:06:26 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 16 13:06:26 SELinux nginx[9331]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 16 13:06:26 SELinux nginx[9331]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 16 13:06:26 SELinux systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jan 16 13:06:26 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@SELinux ~]# ss -tlnp |grep nginx
LISTEN     0      128          *:8088                     *:*                   users:(("nginx",pid=9337,fd=6),("nginx",pid=9336,fd=6))
LISTEN     0      128       [::]:8088                  [::]:*                   users:(("nginx",pid=9337,fd=7),("nginx",pid=9336,fd=7))
[root@SELinux ~]#
```

</details>

**При провижиненге данный метод не заработал**  

<details> <summary> Для создания и применения модуля воспользуемся полученными командой создания модуля: audit2allow -M my-nginx --debug < /var/log/audit/audit.log </summary>

```bash
[root@SELinux ~]# audit2allow -M my-nginx --debug < /var/log/audit/audit.log
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i my-nginx.pp

[root@SELinux ~]# semodule -i my-nginx.pp

[root@SELinux ~]#
[root@SELinux ~]# semodule -l|grep my-nginx
my-nginx        1.0
[root@SELinux ~]# systemctl restart nginx
[root@SELinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2021-01-16 18:33:34 UTC; 2min 5s ago
  Process: 4770 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 4767 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 4766 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 4772 (nginx)
   CGroup: /system.slice/nginx.service
           ├─4772 nginx: master process /usr/sbin/nginx
           └─4773 nginx: worker process

Jan 16 18:33:34 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 16 18:33:34 SELinux nginx[4767]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 16 18:33:34 SELinux nginx[4767]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 16 18:33:34 SELinux systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jan 16 18:33:34 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@SELinux ~]# ss -tnlp |grep nginx
LISTEN     0      128          *:8088                     *:*                   users:(("nginx",pid=4773,fd=6),("nginx",pid=4772,fd=6))
LISTEN     0      128       [::]:8088                  [::]:*                   users:(("nginx",pid=4773,fd=7),("nginx",pid=4772,fd=7))
[root@SELinux ~]#
```

</details>

Проверим загрузку модуля:

```bash
[root@SELinux ~]# semodule -l |grep my-nginx
my-nginx        1.0
[root@SELinux ~]#
```

Модуль создан добавлен в контекст безопасности SELinux. Nginx запущен на порту 8088.  
**Задача выполнена.**

<details> <summary> Для дальнейшего выполнения задания выгрузим модуль SELinux </summary>

```bash
[root@SELinux ~]# semodule -d my-nginx
[root@SELinux ~]# semodule -l |grep my-nginx
[root@SELinux ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@SELinux ~]#
```

</details>

##### Решение 3 переключатели setsebool

Просмотрим булевы значения переключателей для  `nginx`

```bash
[root@SELinux ~]# getsebool -a |grep nginx
[root@SELinux ~]#
```

Каких либо значений не найдено. Обратимся к `auditlog`

```bash
[root@SELinux ~]# sealert -a /var/log/audit/audit.log
100% done
found 1 alerts in /var/log/audit/audit.log
...
If you want to allow nis to enabled
Then you must tell SELinux about this by enabling the 'nis_enabled' boolean.

Do
setsebool -P nis_enabled 1
```

В данном случае мы разрешаем работу сетевой подсистемы `nis`

Воспользуемся командой `setsebool -P nis_enabled 1`

```bash
[root@SELinux ~]# getsebool -a |grep nis_enabled
nis_enabled --> off
[root@SELinux ~]# setsebool -P nis_enabled 1
[root@SELinux ~]# getsebool -a |grep nis_enabled
nis_enabled --> on
[root@SELinux ~]#
```

<details> <summary> Перезапустим nginx и проверим его статус: </summary>

```bash
[root@SELinux ~]# systemctl restart nginx
[root@SELinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2021-01-16 14:27:19 UTC; 12s ago
  Process: 9512 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 9509 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 9508 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 9514 (nginx)
   CGroup: /system.slice/nginx.service
           ├─9514 nginx: master process /usr/sbin/nginx
           └─9515 nginx: worker process

Jan 16 14:27:18 SELinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 16 14:27:19 SELinux nginx[9509]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 16 14:27:19 SELinux nginx[9509]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 16 14:27:19 SELinux systemd[1]: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jan 16 14:27:19 SELinux systemd[1]: Started The nginx HTTP and reverse proxy server.
[root@SELinux ~]# ss -tlnp |grep nginx
LISTEN     0      128          *:8088                     *:*                   users:(("nginx",pid=9515,fd=6),("nginx",pid=9514,fd=6))
LISTEN     0      128       [::]:8088                  [::]:*                   users:(("nginx",pid=9515,fd=7),("nginx",pid=9514,fd=7))
[root@SELinux ~]#
```

</details>

Работа сетевой подсистемы разрешена.  
**Задача выполнена.**


Статья: https://www.tecmint.com/change-nginx-port-in-linux/

### 2. Обеспечить работоспособность приложения при включенном selinux.

- Развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.
К сдаче:
- README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
- Исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.

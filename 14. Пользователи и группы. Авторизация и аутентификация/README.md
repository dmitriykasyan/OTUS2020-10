# Домашнее задание ААА в Linux
## Подготовка  
Настроим стенд согласно рекомендациям из методички:  
Создадим пользователей:  
```bash
vagrant@Lab10 ~$ sudo useradd day && \
sudo useradd night && \
sudo useradd friday
```
 Установим пароли:
 ```bash
vagrant@Lab10 ~$  echo "Otus2019"|sudo passwd --stdin day &&\
 echo "Otus2019" | sudo passwd --stdin night &&\
 echo "Otus2019" | sudo passwd --stdin friday
 ```
Изменим sshd_config для авторизации по паролю:  
```bash
vagrant@Lab10 ~$ sudo sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' \
/etc/ssh/sshd_config && systemctl restart sshd.service
```
## Аутинфикация через модуль pam_time
Просмотрим директорию `/etc/security/`
```bash
root@Lab10 ~# ll /etc/security/
total 52
-rw-r--r--. 1 root root 4564 Apr 11  2018 access.conf
-rw-r--r--. 1 root root   82 Apr 11  2018 chroot.conf
drwxr-xr-x. 2 root root    6 Apr 11  2018 console.apps
-rw-r--r--. 1 root root  604 Apr 11  2018 console.handlers
-rw-r--r--. 1 root root  939 Apr 11  2018 console.perms
drwxr-xr-x. 2 root root    6 Apr 11  2018 console.perms.d
-rw-r--r--. 1 root root 3635 Apr 11  2018 group.conf
-rw-r--r--. 1 root root 2422 Apr 11  2018 limits.conf
drwxr-xr-x. 2 root root   27 Jun  1  2019 limits.d
-rw-r--r--. 1 root root 1440 Apr 11  2018 namespace.conf
drwxr-xr-x. 2 root root    6 Apr 11  2018 namespace.d
-rwxr-xr-x. 1 root root 1019 Apr 11  2018 namespace.init
-rw-------. 1 root root    0 Apr 11  2018 opasswd
-rw-r--r--. 1 root root 2972 Apr 11  2018 pam_env.conf
-rw-r--r--. 1 root root 1718 Dec  6  2011 pwquality.conf
-rw-r--r--. 1 root root  419 Apr 11  2018 sepermit.conf
-rw-r--r--. 1 root root 2179 Apr 11  2018 time.conf
```
Добавим в `/etc/security/time.conf` следуюшие строки:  
```bash
root@Lab10 ~# sh -c 'cat >> /etc/security/time.conf << EOF
> *;*;day;Al0800-2000
> *;*;night;!Al0800-2000
> *;*;friday;Fr0000-2400
> EOF'
```
'Формат даты описывается в файле `/etc/security/time.conf`:  
> the format here is a logic list of day/time-range

Для блокировки пользователя friday во все дни кроме пятницы, необходимо прописать `*;*;friday;Fr0000-2400`  
Просмотрим лог подключений: `root@Lab10 ~# tail -20 /var/log/secure`  
```bash
root@Lab10 ~# date
Wed Apr 29 21:08:17 UTC 2020
root@Lab10 ~# tail -20 /var/log/secure
...
Apr 29 21:05:06 Lab10 sshd[2896]: Failed password for friday from 192.168.11.1 port 39402 ssh2
Apr 29 21:05:06 Lab10 sshd[2896]: fatal: Access denied for user friday by PAM account configuration [preauth]
Apr 29 21:05:21 Lab10 sshd[2900]: Accepted password for night from 192.168.11.1 port 39404 ssh2
Apr 29 21:05:22 Lab10 sshd[2900]: pam_unix(sshd:session): session opened for user night by (uid=0)
Apr 29 21:05:29 Lab10 sshd[2904]: Received disconnect from 192.168.11.1 port 39404:11: disconnected by user
Apr 29 21:05:29 Lab10 sshd[2904]: Disconnected from 192.168.11.1 port 39404
Apr 29 21:05:29 Lab10 sshd[2900]: pam_unix(sshd:session): session closed for user night
Apr 29 21:05:47 Lab10 sshd[2928]: Failed password for day from 192.168.11.1 port 39406 ssh2
Apr 29 21:05:47 Lab10 sshd[2928]: fatal: Access denied for user day by PAM account configuration [preauth]
Apr 29 21:07:22 Lab10 sudo: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/su -l
Apr 29 21:07:22 Lab10 sudo: pam_unix(sudo:session): session opened for user root by vagrant(uid=0)
Apr 29 21:07:22 Lab10 su: pam_unix(su-l:session): session opened for user root by vagrant(uid=0)
```
Модуль pam_time отрабатывает корректно.
## Выполнение домашнего задания
Задание: Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников по ssh

Для выполнения посмотрим как можно управлять доступом для групп.  
PAM  имеет модуль управления группами пользователей: pam_group: http://www.linux-pam.org/Linux-PAM-html/sag-pam_group.html

Для начала проверим наличие группы `admin`:
```bash
root@Lab10 ~# less /etc/group |grep admin
printadmin:x:997:
```
Группа `admin` отсутствует. Создадим пользователей user1, user2 и добавам в группу admin.

```bash
root@Lab10 ~# useradd -m -s /bin/bash user1
root@Lab10 ~# useradd -m -s /bin/bash user2
root@Lab10 ~# echo "Otus2020" | sudo passwd --stdin user1 &&\
> echo "Otus2020" | sudo passwd --stdin user2
Changing password for user user1.
passwd: all authentication tokens updated successfully.
Changing password for user user2.
passwd: all authentication tokens updated successfully.
root@Lab10 ~# groupadd admin &&\
> gpasswd -a user1 admin && \
> gpasswd -a user2 admin
Adding user user1 to group admin
Adding user user2 to group admin
root@Lab10 ~# id u iCloud Keychainser1
uid=1004(user1) gid=1004(user1) groups=1004(user1),1006(admin)
root@Lab10 ~# id user2
uid=1005(user2) gid=1005(user2) groups=1005(user2),1006(admin)
```
Пользователи созданы и добвалены в гуппу `admin`.  
Настроим PAM-модуль управления группами в файле `/etc/security/group.conf`  
Используем следующую форму записи: сервис;терминал;пользователь;время доступа;группа
```bash
*;*;*;Wd0900-2000;*
*;*;*;Al;admin
```
В данном примере мы разрешили аутотенфикацию всем пользователям и всем группам в рабочие дни с 9-00 до 20-00. И доступ группе admin во все дни в любое время.  
Добавим данный модуль в PAM `/etc/pam.d/sshd`  

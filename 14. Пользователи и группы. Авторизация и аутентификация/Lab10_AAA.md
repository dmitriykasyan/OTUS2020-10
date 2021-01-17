# Выполнение домашнего задания

---
## Создаем пользователей
```Bash
[root@Lab10 ~]# useradd -m -s /bin/bash user1
[root@Lab10 ~]# useradd -m -s /bin/bash user2
```
Опция -m создает домашнюю папку,  
Опция -s задает окружение, в частности bash  
В результате получаем следующий вывод:
```Bash
[root@Lab10 home]# tree /home
/home
├── user1
├── user2
└── vagrant
[root@Lab10 home]#
[root@Lab10 home]# ls -la /home/user1
total 12
drwx------. 2 user1 user1  62 Mar 14 17:18 .
drwxr-xr-x. 5 root  root   47 Mar 14 17:18 ..
-rw-r--r--. 1 user1 user1  18 Oct 30  2018 .bash_logout
-rw-r--r--. 1 user1 user1 193 Oct 30  2018 .bash_profile
-rw-r--r--. 1 user1 user1 231 Oct 30  2018 .bashrc
```
---
## Создаем группу и добавляем туда пользователей  
Опция -a, команды gpasswd добовляет пользователя к группе admins. Что можем увидеть ниже:

```bash
[root@Lab10 home]# groupadd admins
[root@Lab10 home]# gpasswd -a user1 admins
Adding user user1 to group admins
[root@Lab10 home]# gpasswd -a user2 admins
Adding user user2 to group admins
[root@Lab10 home]# id user1
uid=1001(user1) gid=1001(user1) groups=1001(user1),1003(admins)
[root@Lab10 home]# id user2
uid=1002(user2) gid=1002(user2) groups=1002(user2),1003(admins)
[root@Lab10 home]#
```
- задание со *  
Выполняем следующюю команду `usermod -g 1003 -G 1002 user1`  
Опция -g задает основную группу.  
Опция -G добовляет группы пользователей.  
В результате выполнения основная группа **gid**, изменилась на **admins**

```bash
[root@Lab10 home]# usermod -g 1003 -G 1001 user1
[root@Lab10 home]# id user1
uid=1001(user1) gid=1003(admins) groups=1003(admins),1001(user1)
[root@Lab10 home]# usermod -g 1003 -G 1002 user2
[root@Lab10 home]# id user2
uid=1002(user2) gid=1003(admins) groups=1003(admins),1002(user2)
[root@Lab10 home]#
```
---
## Создать каталог от рута и дать права группе admins туда писать

```bash
[root@Lab10 ~]# mkdir /opt/upload
[root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxr-xr-x. 2 root root  6 Mar 15 06:52 .
drwxr-xr-x. 4 root root 53 Mar 15 06:52 ..
```

```bash
[root@Lab10 ~]# chmod 770 /opt/upload/
[root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxrwx---. 2 root root  6 Mar 15 06:52 .
drwxr-xr-x. 4 root root 53 Mar 15 06:52 ..
[root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxrwx---. 2 root admins  6 Mar 15 06:52 .
drwxr-xr-x. 4 root root   53 Mar 15 06:52 ..
```
> - что означают права 770 ?  

пользователь - права rwx  
группа пользователей - права rwx  
остальные - доступ запрещен

Расшифровка восьмеричных битов доступа:

|OCTAL|Bits|SUM|  
|:--:|:---:|:--:|
|7|rwx|4+2+1|
|6|rw|4+2|
|5|rx|4+1|
|4|r|4|
|3|wx|2+1|
|2|w|2|
|1|x|1|
|0|0|0|

> - создать по файлу от пользователей user1 и user2 в каталоге /opt/uploads
> - проверьте с какой группой создались файлы от каждого пользователя. Как думаете - почему?

Файлы создались с правами группы `admins`. Так как группа `admins` является основной группой пользователей `user1, user2`.
```Bash
root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxrwx---. 2 root  admins 32 Mar 15 07:35 .
drwxr-xr-x. 4 root  root   53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 Mar 15 07:35 file2
```  
> - * попробуйте сменить текущую группу пользователя newgrp admins у пользователя user2 и создайте еще файл.

Команда `newgrp` изменяет группу текущего пользователя. Пререходим в user2 меняем группу и создаем файл. В результате файл file3 создан с правами группы `admins`.  

```Bash
[root@Lab10 ~]# su user2
[user2@Lab10 root]$
[user2@Lab10 root]$ newgrp admins
[user2@Lab10 root]$ touch /opt/upload/file3
[user2@Lab10 root]$ ls -la /opt/upload/
total 0
drwxrwx---. 2 root  admins 45 Mar 15 07:58 .
drwxr-xr-x. 4 root  root   53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins  0 Mar 15 07:58 file3
```
---
## Создать пользователя user3 и дать ему права писать в /opt/uploads<
> - Создайте пользователя user3
- Попробуйте записать из под него файл в /opt/uploads. Должны получить ошибку

File4 в каталоге /opt/upload не был создан, так как у `user3` отсутствуют права на данный каталог. `User3` не входит в группу `admins`.
```Bash
[root@Lab10 vagrant]#
[root@Lab10 vagrant]# useradd -m -s /bin/bash user3
[root@Lab10 vagrant]# passwd user3
Changing password for user user3.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
[root@Lab10 vagrant]#
[root@Lab10 vagrant]# su user3
[user3@Lab10 vagrant]$ touch /opt/upload/file4
touch: cannot touch ‘/opt/upload/file4’: Отказано в доступе
[user3@Lab10 vagrant]$ id user3
uid=1003(user3) gid=1004(user3) groups=1004(user3)
[user3@Lab10 vagrant]$
```
> - Считайте acl с каталога. Добавьте черерз setfacl права на запись в каталог.

Считав данные ACL из каталога `/opt/upload` мы видим, что у пользователя user3 отутствуют права доступа к каталогу. Добавим пользователя `user3` в ACL каталога `/opt/upload`. После добавления пользователя создание файла произошло успешно. повторно считав данные ACL, видим что права доступа для пользователя добавлены.
```Bash
[root@Lab10 vagrant]# getfacl /opt/upload/
getfacl: Removing leading '/' from absolute path names
# file: opt/upload/
# owner: root
# group: admins
user::rwx
group::rwx
other::---

[root@Lab10 vagrant]#
[root@Lab10 vagrant]# setfacl -m u:user3:rwx /opt/upload/
[root@Lab10 vagrant]# su user3
[user3@Lab10 vagrant]$ touch /opt/upload/user3_file
[user3@Lab10 vagrant]$ ls -la /opt/upload/
total 0
drwxrwx---+ 2 root  admins 63 мар 15 10:19 .
drwxr-xr-x. 4 root  root   53 мар 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 мар 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 мар 15 07:35 file2
-rw-r--r--. 1 user2 admins  0 мар 15 07:58 file3
-rw-rw-r--. 1 user3 user3   0 мар 15 10:19 user3_file
[user3@Lab10 vagrant]$ getfacl /opt/upload/
getfacl: Removing leading '/' from absolute path names
# file: opt/upload/
# owner: root
# group: admins
user::rwx
user:user3:rwx
group::rwx
mask::rwx
other::---

```
---
## Установить GUID флаг на директорию /opt/uploads

В созданном `user3_file2` группа изменена на `admins`, так как установлен SUID бит на каталог `/opt/upload`. При этом изменяются права на права группы владельца каталога `admins`. Не зависимо то того кто создает или изменяет файл.
```Bash
[root@Lab10 vagrant]# chmod g+s /opt/upload/
[root@Lab10 vagrant]# su - user3
Last login: Вс мар 15 10:18:57 UTC 2020 on pts/1
[user3@Lab10 ~]$ touch /opt/upload/user3_file2
[user3@Lab10 ~]$ ls -la /opt/upload/
total 0
drwxrws---+ 2 root  admins 82 Mar 15 10:37 .
drwxr-xr-x. 4 root  root   53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins  0 Mar 15 07:58 file3
-rw-rw-r--. 1 user3 user3   0 Mar 15 10:19 user3_file
-rw-rw-r--. 1 user3 admins  0 Mar 15 10:37 user3_file2
[user3@Lab10 ~]$
```
---
## Установить SUID флаг на выполняемый файл

При попытке считать файл`/etc/shadow` из под пользователя user3 мы получили отказ. Так как права на файл 000.  Данный файл может считать только пользователь `root`. После установки SUID бита на програму `/bin/cat`, запуск процесса происходит с правами владельца файла, `root`, независимо от того какой пользователь произведет запуск. Повторная попытка считать файл`/etc/shadow` из под пользователя user3 прошла успешно.
```Bash
[user3@Lab10 ~]$
[user3@Lab10 ~]$ cat /etc/shadow
cat: /etc/shadow: Permission denied
[user3@Lab10 ~]$ ls -la /etc/shadow
----------. 1 root root 783 Mar 15 10:04 /etc/shadow
[user3@Lab10 ~]$ exit
logout
[root@Lab10 vagrant]# which cat
/bin/cat
[root@Lab10 vagrant]# chmod +s /bin/cat
[root@Lab10 vagrant]# ls -la /bin/cat
-rwsr-sr-x. 1 root root 54160 окт 30  2018 /bin/cat
[root@Lab10 vagrant]# su - user3
Last login: Вс мар 15 10:36:40 UTC 2020 on pts/1
[user3@Lab10 ~]$
[user3@Lab10 ~]$ cat /etc/shadow
root:$1$QDyPlph/$oaAX/xNRf3aiW3l27NIUA/::0:99999:7:::
bin:*:17834:0:99999:7:::
daemon:*:17834:0:99999:7:::
adm:*:17834:0:99999:7:::
lp:*:17834:0:99999:7:::
sync:*:17834:0:99999:7:::
shutdown:*:17834:0:99999:7:::
halt:*:17834:0:99999:7:::
mail:*:17834:0:99999:7:::
operator:*:17834:0:99999:7:::
games:*:17834:0:99999:7:::
ftp:*:17834:0:99999:7:::
nobody:*:17834:0:99999:7:::
systemd-network:!!:18048::::::
dbus:!!:18048::::::
polkitd:!!:18048::::::
rpc:!!:18048:0:99999:7:::
rpcuser:!!:18048::::::
nfsnobody:!!:18048::::::
sshd:!!:18048::::::
postfix:!!:18048::::::
chrony:!!:18048::::::
vagrant:$1$C93uBBDg$pqzqtS3a9llsERlv..YKs1::0:99999:7:::
vboxadd:!!:18335::::::
user1:!!:18335:0:99999:7:::
user2:!!:18335:0:99999:7:::
user3:$1$WJbOpXil$zzCCvc8p93rJYU/cBJ4x6.:18336:0:99999:7:::
[user3@Lab10 ~]$
```
---
## Сменить владельца /opt/uploads на user3 и добавить sticky bit
>- Объясните почему user3 смог удалить файл, который ему не принадлежит  

Определение:  
Stiky Bit - используется в основном для каталогов, чтобы защитить в них файлы. Из такого каталога пользователь может удалить только те файлы, владельцем которых он является.

В данном случае удаление файла созданного пользователем `user3` прошло успешно, по причине установки на каталог **SUID** бита. выполнение операций с файлами в данном случае происходит от владельца каталога `user3`
```Bash
[root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxrws--T+ 2 user3 admins 82 Mar 15 10:37 .
...
```
Листинг комманд.

```Bash
[root@Lab10 ~]# chown user3 /opt/upload/
[root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxrws---+ 2 user3 admins 82 Mar 15 10:37 .
drwxr-xr-x. 4 root  root   53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins  0 Mar 15 07:58 file3
-rw-rw-r--. 1 user3 user3   0 Mar 15 10:19 user3_file
-rw-rw-r--. 1 user3 admins  0 Mar 15 10:37 user3_file2
[root@Lab10 ~]# chmod +t /opt/upload/
[root@Lab10 ~]# ls -la /opt/upload/
total 0
drwxrws--T+ 2 user3 admins 82 Mar 15 10:37 .
drwxr-xr-x. 4 root  root   53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins  0 Mar 15 07:58 file3
-rw-rw-r--. 1 user3 user3   0 Mar 15 10:19 user3_file
-rw-rw-r--. 1 user3 admins  0 Mar 15 10:37 user3_file2
[root@Lab10 ~]# su - user1
Last login: Sun Mar 15 07:34:05 UTC 2020 on pts/0
[user1@Lab10 ~]$ touch /opt/upload/user1_file_test
[user1@Lab10 ~]$ ls -la /opt/upload/
total 0
drwxrws--T+ 2 user3 admins 105 Mar 15 13:30 .
drwxr-xr-x. 4 root  root    53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins   0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins   0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins   0 Mar 15 07:58 file3
-rw-r--r--. 1 user1 admins   0 Mar 15 13:30 user1_file_test
-rw-rw-r--. 1 user3 user3    0 Mar 15 10:19 user3_file
-rw-rw-r--. 1 user3 admins   0 Mar 15 10:37 user3_file2
[user1@Lab10 ~]$ su - user3
Password:
Last login: Sun Mar 15 10:56:38 UTC 2020 on pts/1
[user3@Lab10 ~]$ rm -f /opt/upload/user1_file_test
```
>- Создайте теперь файл от user1 и удалите его пользователем user1  
Объясните результат

Хотя владельцем `/opt/upload` являяется `user3` создание и удаление произошло успешно. Так как на каталоге установлен **SUID** бит.

```Bash
[user3@Lab10 ~]$ exit
logout
[user1@Lab10 ~]$ touch /opt/upload/user1_file_test1
[user1@Lab10 ~]$ ls -la /opt/upload/
total 0
drwxrws--T+ 2 user3 admins 106 Mar 15 13:32 .
drwxr-xr-x. 4 root  root    53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins   0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins   0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins   0 Mar 15 07:58 file3
-rw-r--r--. 1 user1 admins   0 Mar 15 13:32 user1_file_test1
-rw-rw-r--. 1 user3 user3    0 Mar 15 10:19 user3_file
-rw-rw-r--. 1 user3 admins   0 Mar 15 10:37 user3_file2
[user1@Lab10 ~]$ rm -f /opt/upload/user1_file_test1
[user1@Lab10 ~]$ ls -la /opt/upload/
total 0
drwxrws--T+ 2 user3 admins 82 Mar 15 13:32 .
drwxr-xr-x. 4 root  root   53 Mar 15 06:52 ..
-rw-r--r--. 1 user1 admins  0 Mar 15 07:34 file1
-rw-r--r--. 1 user2 admins  0 Mar 15 07:35 file2
-rw-r--r--. 1 user2 admins  0 Mar 15 07:58 file3
-rw-rw-r--. 1 user3 user3   0 Mar 15 10:19 user3_file
-rw-rw-r--. 1 user3 admins  0 Mar 15 10:37 user3_file2
[user1@Lab10 ~]$
```
---
## Записи в sudoers

https://serversforhackers.com/c/sudo-and-sudoers-configuration


```Bash
[root@Lab10 ~]# su - user3
Last login: Sun Mar 15 13:31:03 UTC 2020 on pts/0
[user3@Lab10 ~]$ sudo -l /root

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for user3:
sudo: list: command not found
[user3@Lab10 ~]$ sudo -l
[sudo] password for user3:
Sorry, user user3 may not run sudo on Lab10.
[user3@Lab10 ~]$ id user3
uid=1003(user3) gid=1004(user3) groups=1004(user3)
```

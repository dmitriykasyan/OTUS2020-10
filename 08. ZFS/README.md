# Домашнее задание *файловая система ZFS*
## Подготовка стенда
Запустим предоставленный стенд и подключимся к машине `server`. Запустим модуль ядра `modprobe zfs` и проверим вывод lsmod  
<details><summary>lsmod</summary>

```bash
[root@server ~]# lsmod
Module                  Size  Used by
sunrpc                454656  1
zfs                  4202496  8
zunicode              335872  1 zfs
zlua                  176128  1 zfs
intel_rapl_msr         16384  0
intel_rapl_common      24576  1 intel_rapl_msr
intel_powerclamp       16384  0
crct10dif_pclmul       16384  1
crc32_pclmul           16384  0
ghash_clmulni_intel    16384  0
zcommon                94208  1 zfs
znvpair                90112  2 zfs,zcommon
zavl                   16384  1 zfs
icp                   323584  1 zfs
intel_rapl_perf        20480  0
pcspkr                 16384  0
spl                   126976  5 zfs,icp,znvpair,zcommon,zavl
snd_intel8x0           45056  0
snd_ac97_codec        143360  1 snd_intel8x0
ac97_bus               16384  1 snd_ac97_codec
snd_pcm               110592  2 snd_intel8x0,snd_ac97_codec
snd_timer              36864  1 snd_pcm
snd                    94208  4 snd_intel8x0,snd_timer,snd_ac97_codec,snd_pcm
video                  45056  0
soundcore              16384  1 snd
i2c_piix4              24576  0
ip_tables              28672  0
xfs                  1519616  1
libcrc32c              16384  1 xfs
sd_mod                 53248  10
sg                     40960  0
ata_generic            16384  0
ahci                   40960  4
libahci                40960  1 ahci
ata_piix               36864  1
libata                270336  4 ata_piix,libahci,ahci,ata_generic
crc32c_intel           24576  1
serio_raw              16384  0
e1000                 151552  0
[root@server ~]# 1
```
</details>
Посмотрим доступные диски:
<details><summary>lsblk</summary>

```bash
[root@server ~]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  10G  0 disk
└─sda1   8:1    0  10G  0 part /
sdb      8:16   0   1G  0 disk
sdc      8:32   0   1G  0 disk
sdd      8:48   0   1G  0 disk
sde      8:64   0   1G  0 disk
sdf      8:80   0   1G  0 disk
```
</details>

Для выполнения заданий соберем пул `raidz1` из дисков `sdb`,`sdc`,`sdb`,`sde`  
Командой: <details><summary>zpool create storage raidz1 sd{b..e}</summary>
```bash
[root@server ~]# zpool create storage raidz1 sd{b..e}
[root@server ~]# zpool status -v
  pool: storage
   state: ONLINE
     scan: none requested
     config:

             NAME        STATE     READ WRITE CKSUM
             storage     ONLINE       0     0     0
               raidz1-0  ONLINE       0     0     0
                 sdb     ONLINE       0     0     0
                 sdc     ONLINE       0     0     0
                 sdd     ONLINE       0     0     0
                 sde     ONLINE       0     0     0

errors: No known data errors
[root@server ~]#
```
</details>

Пул ZFS `storage` создан.  
Стенд подготовлен.

## Задание 1. Определить алгоритм с наилучшим сжатием
 Зачем:
Отрабатываем навыки работы с созданием томов и установкой параметров. Находим наилучшее сжатие.

Шаги:
- определить какие алгоритмы сжатия поддерживает zfs (gzip gzip-N, zle lzjb, lz4)
- создать 4 файловых системы на каждой применить свой алгоритм сжатия
Для сжатия использовать либо текстовый файл либо группу файлов:
- скачать файл “Война и мир” и расположить на файловой системе
wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8
- либо скачать файл ядра распаковать и расположить на файловой системе
Результат:
- список команд которыми получен результат с их выводами
- вывод команды из которой видно какой из алгоритмов лучше


### Выполнение задания

Файловую систему можно создать двумя путями:
- задать необходимые опции при создании ФС: `zfs create [-ps] [-b blocksize] [-o property=value]... -V size volume`
- задать необходимые опции после создания ФС: `zfs set property=value [property=value]... filesystem|volume|snapshot...`  
Попробуем воспользоваться обеими путями.  

#### Создание файловых систем
Алгоритмы сжатия работают только с данными размещенными на ФС с настроенной компрессией. Поэтому создадим ФС с разной компрессией:  

#### Алгоритм сжатия gzip-9

<details><summary>zfs create -p -o compression=gzip-9 storage/folder_gzip-9</summary>

```bash
[root@server ~]# zfs create -p -o compression=gzip-9 storage/folder_gzip-9
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
storage                 176K  2.68G     35.2K  /storage
storage/folder_gzip-9  32.9K  2.68G     32.9K  /storage/folder_gzip-9
[root@server ~]# zfs get all storage/folder_gzip-9
NAME                   PROPERTY              VALUE                   SOURCE
storage/folder_gzip-9  type                  filesystem              -
storage/folder_gzip-9  creation              Wed Nov 25  9:19 2020   -
storage/folder_gzip-9  used                  32.9K                   -
storage/folder_gzip-9  available             2.68G                   -
storage/folder_gzip-9  referenced            32.9K                   -
storage/folder_gzip-9  compressratio         1.00x                   -
storage/folder_gzip-9  mounted               yes                     -
storage/folder_gzip-9  quota                 none                    default
storage/folder_gzip-9  reservation           none                    default
storage/folder_gzip-9  recordsize            128K                    default
storage/folder_gzip-9  mountpoint            /storage/folder_gzip-9  default
storage/folder_gzip-9  sharenfs              off                     default
storage/folder_gzip-9  checksum              on                      default
storage/folder_gzip-9  compression           gzip-9                  local
storage/folder_gzip-9  atime                 on                      default
storage/folder_gzip-9  devices               on                      default
...
```
</details>

#### Алгоритм сжатия zle  

<details><summary> zfs create -p -o compression=zle storage/folder_zle </summary>

```bash
[root@server ~]# zfs create -p -o compression=zle storage/folder_zle
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
storage                 218K  2.68G     35.9K  /storage
storage/folder_gzip-9  32.9K  2.68G     32.9K  /storage/folder_gzip-9
storage/folder_zle     32.9K  2.68G     32.9K  /storage/folder_zle
[root@server ~]# zfs get all storage/folder_zle
NAME                PROPERTY              VALUE                  SOURCE
storage/folder_zle  type                  filesystem             -
storage/folder_zle  creation              Wed Nov 25  9:50 2020  -
storage/folder_zle  used                  32.9K                  -
storage/folder_zle  available             2.68G                  -
storage/folder_zle  referenced            32.9K                  -
storage/folder_zle  compressratio         1.00x                  -
storage/folder_zle  mounted               yes                    -
storage/folder_zle  quota                 none                   default
storage/folder_zle  reservation           none                   default
storage/folder_zle  recordsize            128K                   default
storage/folder_zle  mountpoint            /storage/folder_zle    default
storage/folder_zle  sharenfs              off                    default
storage/folder_zle  checksum              on                     default
storage/folder_zle  compression           zle                    local
storage/folder_zle  atime                 on                     default
```
</details>

#### Алгоритм сжатия lzjb

<details>
<summary> zfs create -p -o compression=lzjb storage/folder_lzjb </summary>

```bash
[root@server ~]# zfs create -p -o compression=lzjb storage/folder_lzjb
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
storage                 251K  2.68G     35.9K  /storage
storage/folder_gzip-9  32.9K  2.68G     32.9K  /storage/folder_gzip-9
storage/folder_lzjb    32.9K  2.68G     32.9K  /storage/folder_lzjb
storage/folder_zle     32.9K  2.68G     32.9K  /storage/folder_zle
[root@server ~]# zfs get all storage/folder_lzjb
NAME                 PROPERTY              VALUE                  SOURCE
storage/folder_lzjb  type                  filesystem             -
storage/folder_lzjb  creation              Wed Nov 25  9:59 2020  -
storage/folder_lzjb  used                  32.9K                  -
storage/folder_lzjb  available             2.68G                  -
storage/folder_lzjb  referenced            32.9K                  -
storage/folder_lzjb  compressratio         1.00x                  -
storage/folder_lzjb  mounted               yes                    -
storage/folder_lzjb  quota                 none                   default
storage/folder_lzjb  reservation           none                   default
storage/folder_lzjb  recordsize            128K                   default
storage/folder_lzjb  mountpoint            /storage/folder_lzjb   default
storage/folder_lzjb  sharenfs              off                    default
storage/folder_lzjb  checksum              on                     default
storage/folder_lzjb  compression           lzjb                   local
storage/folder_lzjb  atime                 on                     default
```
</details>

#### Алгоритм сжатия lz4
Создадим ФС `storage/folder_lz4`
<details>
<summary> Вывод </summary>

```bash
[root@server ~]# zfs create storage/folder_lz4
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
storage                 299K  2.68G     37.4K  /storage
storage/folder_gzip-9  32.9K  2.68G     32.9K  /storage/folder_gzip-9
storage/folder_lz4     32.9K  2.68G     32.9K  /storage/folder_lz4
storage/folder_lzjb    32.9K  2.68G     32.9K  /storage/folder_lzjb
storage/folder_zle     32.9K  2.68G     32.9K  /storage/folder_zle
[root@server ~]# zfs get all storage/folder_lz4
NAME                PROPERTY              VALUE                  SOURCE
storage/folder_lz4  type                  filesystem             -
storage/folder_lz4  creation              Wed Nov 25 10:30 2020  -
storage/folder_lz4  used                  32.9K                  -
storage/folder_lz4  available             2.68G                  -
storage/folder_lz4  referenced            32.9K                  -
storage/folder_lz4  compressratio         1.00x                  -
storage/folder_lz4  mounted               yes                    -
storage/folder_lz4  quota                 none                   default
storage/folder_lz4  reservation           none                   default
storage/folder_lz4  recordsize            128K                   default
storage/folder_lz4  mountpoint            /storage/folder_lz4    default
storage/folder_lz4  sharenfs              off                    default
storage/folder_lz4  checksum              on                     default
storage/folder_lz4  compression           off                    default
storage/folder_lz4  atime                 on                     default
storage/folder_lz4  devices               on                     default
```
</details>

В ФС storage/folder_lz4 сжатие отсутствует:  
`storage/folder_lz4  compression           off                    default`  
Так как ФС `folder_lz4` при создании наследует свойства корневой ФС.  
Добавим опции сжатия:`zfs set compression=lz4 storage/folder_lz4`

<details>
<summary> zfs set compression=lz4 storage/folder_lz4 </summary>

```bash
[root@server ~]# zfs set compression=lz4 storage/folder_lz4
[root@server ~]# zfs get all storage/folder_lz4
NAME                PROPERTY              VALUE                  SOURCE
storage/folder_lz4  type                  filesystem             -
storage/folder_lz4  creation              Wed Nov 25 10:30 2020  -
storage/folder_lz4  used                  32.9K                  -
storage/folder_lz4  available             2.68G                  -
storage/folder_lz4  referenced            32.9K                  -
storage/folder_lz4  compressratio         1.00x                  -
storage/folder_lz4  mounted               yes                    -
storage/folder_lz4  quota                 none                   default
storage/folder_lz4  reservation           none                   default
storage/folder_lz4  recordsize            128K                   default
storage/folder_lz4  mountpoint            /storage/folder_lz4    default
storage/folder_lz4  sharenfs              off                    default
storage/folder_lz4  checksum              on                     default
storage/folder_lz4  compression           lz4                    local
storage/folder_lz4  atime                 on                     default
```
</details>

Файловые системы созданы:
```bash
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
storage                 301K  2.68G     37.4K  /storage
storage/folder_gzip-9  32.9K  2.68G     32.9K  /storage/folder_gzip-9
storage/folder_lz4     32.9K  2.68G     32.9K  /storage/folder_lz4
storage/folder_lzjb    32.9K  2.68G     32.9K  /storage/folder_lzjb
storage/folder_zle     32.9K  2.68G     32.9K  /storage/folder_zle
[root@server ~]#
```
Скачаем файл и скопируем в созданные ФС
<details>
<summary> wget -O War_and_Peace.txt http://www.gutenberg.org/files/2600/2600-0.txt </summary>

```bash
[root@server ~]# wget -O War_and_Peace.txt http://www.gutenberg.org/files/2600/2600-0.txt
--2020-11-25 10:56:42--  http://www.gutenberg.org/files/2600/2600-0.txt
Resolving www.gutenberg.org (www.gutenberg.org)... 152.19.134.47
Connecting to www.gutenberg.org (www.gutenberg.org)|152.19.134.47|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3359584 (3.2M) [text/plain]
Saving to: ‘War_and_Peace.txt’

War_and_Peace.txt                     100%[=======================================================================>]   3.20M   302KB/s    in 12s

2020-11-25 10:56:55 (270 KB/s) - ‘War_and_Peace.txt’ saved [3359584/3359584]

[root@server ~]# ls -lah
total 3.3M
dr-xr-x---.  3 root root  213 Nov 25 10:54 .
dr-xr-xr-x. 19 root root  270 Nov 24 15:41 ..
-rw-------.  1 root root 5.1K Jun 11 02:38 anaconda-ks.cfg
-rw-------.  1 root root  219 Nov 24 16:45 .bash_history
-rw-r--r--.  1 root root   18 May 11  2019 .bash_logout
-rw-r--r--.  1 root root  176 May 11  2019 .bash_profile
-rw-r--r--.  1 root root  176 May 11  2019 .bashrc
-rw-r--r--.  1 root root  100 May 11  2019 .cshrc
drwx------.  2 root root   25 Nov 24 15:28 .gnupg
-rw-------.  1 root root   38 Nov 25 08:43 .lesshst
-rw-------.  1 root root 4.9K Jun 11 02:38 original-ks.cfg
-rw-r--r--.  1 root root  129 May 11  2019 .tcshrc
-rw-r--r--.  1 root root 3.3M Aug  6 14:10 War_and_Peace.txt
[root@server ~]#
```
</details>

Скопируем файл в созданные ФС
```bash
[root@server ~]# cp War_and_Peace.txt /storage/folder_gzip-8
[root@server ~]# cp War_and_Peace.txt /storage/folder_lz4
[root@server ~]# cp War_and_Peace.txt /storage/folder_lzjb
[root@server ~]# cp War_and_Peace.txt /storage/folder_zle
```
Посмотрим объем занимаемого пространства и степень сжатия в различных ФС:
<details>
<summary>Вывод</summary>

```bash
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
storage                9.18M  2.67G     37.4K  /storage
storage/folder_gzip-9  1.25M  2.67G     1.25M  /storage/folder_gzip-9
storage/folder_lz4     2.03M  2.67G     2.03M  /storage/folder_lz4
storage/folder_lzjb    2.42M  2.67G     2.42M  /storage/folder_lzjb
storage/folder_zle     3.24M  2.67G     3.24M  /storage/folder_zle
[root@server ~]# zfs get -r compressratio storage
NAME                   PROPERTY       VALUE  SOURCE
storage                compressratio  1.47x  -
storage/folder_gzip-9  compressratio  2.67x  -
storage/folder_lz4     compressratio  1.62x  -
storage/folder_lzjb    compressratio  1.36x  -
storage/folder_zle     compressratio  1.01x  -
[root@server ~]#
[root@server ~]# tree -sh /storage/
/storage/
├── [    3]  folder_gzip-9
│   └── [ 3.2M]  War_and_Peace.txt
├── [    3]  folder_lz4
│   └── [ 3.2M]  War_and_Peace.txt
├── [    3]  folder_lzjb
│   └── [ 3.2M]  War_and_Peace.txt
└── [    3]  folder_zle
    └── [ 3.2M]  War_and_Peace.txt
```
</details>


### Вывод
Наилучшую степень сжатия показал алгоритм `gzip` со степенью сжатия 9.  
Удивило, что ОС при выводе показала полный объем файла не учитывая степень сжатия файловой системой.


## **Задание 2.  Определить настройки pool’a**
Зачем:
Для переноса дисков между системами используется функция export/import. Отрабатываем навыки работы с файловой системой ZFS
Шаги
Загрузить архив с файлами локально.
https://drive.google.com/open?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Распаковать.
С помощью команды zfs import собрать pool ZFS.
Командами zfs определить настройки
- размер хранилища
- тип pool
- значение recordsize
- какое сжатие используется
- какая контрольная сумма используется
Результат:
- список команд которыми восстановили pool . Желательно с  Output команд.
- файл с описанием настроек settings

### Выполнение задания
Для выполнения задания скачаем и распакуем файл:
<details>
<summary> Скачаем файл </summary>

```bash
[root@server ~]# wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O otus_task2.gz
--2020-11-25 13:25:04--  https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Resolving docs.google.com (docs.google.com)... 64.233.162.194
Connecting to docs.google.com (docs.google.com)|64.233.162.194|:443... connected.
HTTP request sent, awaiting response... 302 Moved Temporarily
Location: https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/okpg8hf0qvrqi26o52vhmnmnar4375ua/1606310700000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download [following]
Warning: wildcards not supported in HTTP.
--2020-11-25 13:25:14--  https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/okpg8hf0qvrqi26o52vhmnmnar4375ua/1606310700000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download
Resolving doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)... 64.233.165.132
Connecting to doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)|64.233.165.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/x-gzip]
Saving to: ‘otus_task2.gz’

otus_task2.gz                             [           <=>                                                          ]   6.94M  2.57MB/s    in 2.7s

2020-11-25 13:25:17 (2.57 MB/s) - ‘otus_task2.gz’ saved [7275140]

[root@server ~]# ls -lah
total 11M
dr-xr-x---.  3 root root  268 Nov 25 13:25 .
dr-xr-xr-x. 19 root root  270 Nov 24 15:41 ..
-rw-------.  1 root root 5.1K Jun 11 02:38 anaconda-ks.cfg
-rw-------.  1 root root  219 Nov 24 16:45 .bash_history
-rw-r--r--.  1 root root   18 May 11  2019 .bash_logout
-rw-r--r--.  1 root root  176 May 11  2019 .bash_profile
-rw-r--r--.  1 root root  176 May 11  2019 .bashrc
-rw-r--r--.  1 root root  100 May 11  2019 .cshrc
drwx------.  2 root root   25 Nov 24 15:28 .gnupg
-rw-------.  1 root root   38 Nov 25 08:43 .lesshst
-rw-------.  1 root root 4.9K Jun 11 02:38 original-ks.cfg
-rw-r--r--.  1 root root 7.0M Nov 25 13:25 otus_task2.gz
-rw-r--r--.  1 root root  129 May 11  2019 .tcshrc
-rw-r--r--.  1 root root 3.3M Aug  6 14:10 War_and_Peace.txt
-rw-r--r--.  1 root root  171 Nov 25 13:02 .wget-hsts
-rw-r--r--.  1 root root  318 Nov 25 13:05 wget-log
[root@server ~]# file otus_task2.gz
otus_task2.gz: gzip compressed data, last modified: Fri May 15 05:00:29 2020, from Unix, original size 1048586240
[root@server ~]# gunzip otus_task2.gz
[root@server ~]# ls -lah
total 1004M
dr-xr-x---.  3 root root   265 Nov 25 13:27 .
dr-xr-xr-x. 19 root root   270 Nov 24 15:41 ..
-rw-------.  1 root root  5.1K Jun 11 02:38 anaconda-ks.cfg
-rw-------.  1 root root   219 Nov 24 16:45 .bash_history
-rw-r--r--.  1 root root    18 May 11  2019 .bash_logout
-rw-r--r--.  1 root root   176 May 11  2019 .bash_profile
-rw-r--r--.  1 root root   176 May 11  2019 .bashrc
-rw-r--r--.  1 root root   100 May 11  2019 .cshrc
drwx------.  2 root root    25 Nov 24 15:28 .gnupg
-rw-------.  1 root root    38 Nov 25 08:43 .lesshst
-rw-------.  1 root root  4.9K Jun 11 02:38 original-ks.cfg
-rw-r--r--.  1 root root 1001M Nov 25 13:25 otus_task2
-rw-r--r--.  1 root root   129 May 11  2019 .tcshrc
-rw-r--r--.  1 root root  3.3M Aug  6 14:10 War_and_Peace.txt
-rw-r--r--.  1 root root   171 Nov 25 13:02 .wget-hsts
-rw-r--r--.  1 root root   318 Nov 25 13:05 wget-log
[root@server ~]#
```
</details>

Определим тип файла `otus_task2`:
```bash
[root@server ~]# file otus_task2
otus_task2: POSIX tar archive (GNU)
```
Разархивируем `otus_task2`:
```bash
[root@server ~]# tar -xf otus_task2
[root@server ~]# ls
anaconda-ks.cfg  original-ks.cfg  otus_task2  War_and_Peace.txt  wget-log  zpoolexport
```
Просмотрим данные в и их тип в `zpoolexport`:
```bash
[root@server ~]# ls zpoolexport/
filea  fileb
[root@server ~]# file zpoolexport/filea
zpoolexport/filea: data
[root@server ~]#
```
Посмотрим тип пула и имроптируем его по id
```bash
[root@server ~]# zpool import -d zpoolexport/filea
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

                    otus                         ONLINE
                      mirror-0                   ONLINE
                        /root/zpoolexport/filea  ONLINE
                        /root/zpoolexport/fileb  ONLINE
[root@server ~]# zpool import  -d zpoolexport/filea 6554193320433390805


[root@server zpoolexport]# zpool list
NAME      SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus      480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -
storage  3.75G  12.4M  3.74G        -         -     0%     0%  1.00x    ONLINE  -
[root@server zpoolexport]#
```
Скачаный пул ZFS является файловым пулом. Собранном в режиме mirror. Объемом 480 Мб:

```bash
[root@server zpoolexport]# zpool status -v
  pool: otus
   state: ONLINE
     scan: none requested
     config:

             NAME                         STATE     READ WRITE CKSUM
             otus                         ONLINE       0     0     0
               mirror-0                   ONLINE       0     0     0
                 /root/zpoolexport/filea  ONLINE       0     0     0
                 /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: storage
   state: ONLINE
     scan: none requested
     config:

             NAME        STATE     READ WRITE CKSUM
             storage     ONLINE       0     0     0
               raidz1-0  ONLINE       0     0     0
                 sdb     ONLINE       0     0     0
                 sdc     ONLINE       0     0     0
                 sdd     ONLINE       0     0     0
                 sde     ONLINE       0     0     0

errors: No known data errors
[root@server zpoolexport]#
```
Посмотрим содержимое ФС и точки монтирования:
<details>
<summary> Вывод </summary>

```bash
[root@server zpoolexport]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
otus                   1.97M   350M       24K  /otus
otus/hometask2         1.80M   350M     1.80M  /otus/hometask2
storage                9.19M  2.67G     37.4K  /storage
storage/folder_gzip-9  1.25M  2.67G     1.25M  /storage/folder_gzip-9
storage/folder_lz4     2.03M  2.67G     2.03M  /storage/folder_lz4
storage/folder_lzjb    2.42M  2.67G     2.42M  /storage/folder_lzjb
storage/folder_zle     3.24M  2.67G     3.24M  /storage/folder_zle
[root@server zpoolexport]# ls /otus/hometask2/
dir1    dir13  dir18  dir22  dir27  dir31  dir36  dir40  dir45  dir5   dir54  dir59  dir63  dir68  dir72  dir77  dir81  dir86  dir90  dir95
dir10   dir14  dir19  dir23  dir28  dir32  dir37  dir41  dir46  dir50  dir55  dir6   dir64  dir69  dir73  dir78  dir82  dir87  dir91  dir96
dir100  dir15  dir2   dir24  dir29  dir33  dir38  dir42  dir47  dir51  dir56  dir60  dir65  dir7   dir74  dir79  dir83  dir88  dir92  dir97
dir11   dir16  dir20  dir25  dir3   dir34  dir39  dir43  dir48  dir52  dir57  dir61  dir66  dir70  dir75  dir8   dir84  dir89  dir93  dir98
dir12   dir17  dir21  dir26  dir30  dir35  dir4   dir44  dir49  dir53  dir58  dir62  dir67  dir71  dir76  dir80  dir85  dir9   dir94  dir99
[root@server zpoolexport]#
```
</details>

Получим свойства ФС `otus`
```bash
[root@server zpoolexport]# zfs get -s local all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  recordsize            128K                   local
otus  checksum              sha256                 local
otus  compression           zle                    local
```
Задание выполнено.

## **Задание 3. Найти сообщение от преподавателей**
Зачем:
для бэкапа используются технологии snapshot. Snapshot можно передавать между хостами и восстанавливать с помощью send/receive. Отрабатываем навыки восстановления snapshot и переноса файла.
Шаги:
Скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing
Файл был получен командой
zfs send otus/storage@task2 > otus_task2.file
Восстановить его локально. zfs receive
Найти зашифрованное сообщение в файле secret_message
Результат:
- список шагов которыми восстанавливали
- зашифрованное сообщение

### Выполнение задания

Загрузим файл по ссылке с https://drive.google.com в файл `otus_task3`.
<details>
<summary> Вывод </summary>

```bash
[root@server ~]# wget --no-check-certificate 'https://drive.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O otus_task3
--2020-11-28 10:33:31--  https://drive.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Resolving drive.google.com (drive.google.com)... 64.233.162.194
Connecting to drive.google.com (drive.google.com)|64.233.162.194|:443... connected.
HTTP request sent, awaiting response... 302 Moved Temporarily
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/5jsuuiedg2t2hd49gg1uihpr1uouj195/1606559550000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download [following]
Warning: wildcards not supported in HTTP.
--2020-11-28 10:33:33--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/5jsuuiedg2t2hd49gg1uihpr1uouj195/1606559550000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 173.194.73.132
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|173.194.73.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/octet-stream]
Saving to: ‘otus_task3’

otus_task3                                [      <=>                                                               ]   5.18M  3.67MB/s    in 1.4s

2020-11-28 10:33:35 (3.67 MB/s) - ‘otus_task3’ saved [5432736]

[root@server ~]# ls -l
total 1032620
-rw-------. 1 root root       5166 Jun 11 02:38 anaconda-ks.cfg
-rw-------. 1 root root       5006 Jun 11 02:38 original-ks.cfg
-rw-r--r--. 1 root root 1048586240 Nov 25 13:25 otus_task2
-rw-r--r--. 1 root root    5432736 Nov 28 10:33 otus_task3
-rw-r--r--. 1 root root    3359584 Aug  6 14:10 War_and_Peace.txt
drwxr-xr-x. 2 root root         32 May 15  2020 zpoolexport
[root@server ~]#
```
</details>

Определим тип скачанного файла:
```bash
[root@server ~]# file otus_task3
otus_task3: ZFS shapshot (little-endian machine), version 17, type: ZFS, destination GUID: 70 B1 CE AB 92 00 51 35, name: 'otus/storage@task2'
[root@server ~]#
```
Импортируем снапшот в ФС /otus:
```bash
[root@server ~]# zfs receive otus/storage@task2 < otus_task3
[root@server ~]# zfs list -t snapshot
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus/storage@task2     0B      -     2.83M  -
```
Восстановим файлы из снапшота:
```bash
[root@server ~]# zfs rollback otus/storage@task2
[root@server ~]# zfs list
NAME                    USED  AVAIL     REFER  MOUNTPOINT
otus                   4.94M   347M       25K  /otus
otus/hometask2         1.88M   347M     1.88M  /otus/hometask2
otus/storage           2.83M   347M     2.83M  /otus/storage
storage                9.19M  2.67G     37.4K  /storage
storage/folder_gzip-9  1.25M  2.67G     1.25M  /storage/folder_gzip-9
storage/folder_lz4     2.03M  2.67G     2.03M  /storage/folder_lz4
storage/folder_lzjb    2.42M  2.67G     2.42M  /storage/folder_lzjb
storage/folder_zle     3.24M  2.67G     3.24M  /storage/folder_zle
[root@server ~]# ls /otus/storage/
10M.file  cinderella.tar  for_examaple.txt  homework4.txt  Limbo.txt  Moby_Dick.txt  task1  War_and_Peace.txt  world.sql
[root@server ~]# zfs list -t snapshot
NAME                 USED  AVAIL     REFER  MOUNTPOINT
otus/storage@task2    17K      -     2.83M  -
[root@server ~]#
```
Перейдем в директорию `/otus/storage` и надем файл `secret_message`
```bash
[root@server storage]# find . -name secret_message
./task1/file_mess/secret_message
[root@server storage]# cat task1/file_mess/secret_message
https://github.com/sindresorhus/awesome
[root@server storage]# tar -tvf cinderella.tar |grep secret
[root@server storage]#
```
Поиск в архиве не дал результата.  
В сообщении содержится ссылка на ГитХаб )))

Задание выполнено.

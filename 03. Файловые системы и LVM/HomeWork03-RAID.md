# Домашняя работа
## Задание
1. Добавить в Vagrantfile еще дисков
1. Собрать RAID 5
1. Прописать собранный рейд в конф, чтобы рейд собирался при загрузке
1. Сломать/починить raid
1. Создать GPT раздел и 5 партиций

## Добавить в Vagrantfile еще дисков

Запуск лабораторной машины. Проверка монтирования дисков  
```
[vagrant@otuslinux ~]$ sudo fdisk -l

Disk /dev/sda: 42.9 GB, 42949672960 bytes, 83886080 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x0009ef88

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    83886079    41942016   83  Linux
[vagrant@otuslinux ~]$
```

Отключим терминал и остановим лабораторную машину  
Добавим диск по методичке в Vagrant-файл

```
:sata5 => {
      :dfile => './sata5.vdi',
      :size => 250, # Megabytes
      :port => 5
      }  
```

запуск лабораторной машины и проверка количества подключенных дисков:
```
[vagrant@otuslinux ~]$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
`-sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
[vagrant@otuslinux ~]$ mount |grep sd
/dev/sda1 on / type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
[vagrant@otuslinux ~]$
```
или:
```

[vagrant@otuslinux ~]$ lsscsi
[0:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sda
[3:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdb
[4:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdc
[5:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sdd
[6:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sde
```
## Создание и сборка RAID 5

Занулим суперблоки:
```
[vagrant@otuslinux ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
```
создадим RAID 5
```
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 5 -n 4 /dev/sd{b,c,d,e}
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
[vagrant@otuslinux ~]$
```
проверка сборки массива
```
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid5 sde[4] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]

unused devices: <none>
[vagrant@otuslinux ~]$
```
```
[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Feb  9 09:39:52 2020
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Feb  9 09:39:55 2020
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 3d6f0079:eb31680b:32ffdc79:ff1ff690
            Events : 18

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       4       8       64        3      active sync   /dev/sde
[vagrant@otuslinux ~]$
```
## Прописать собранный рейд в конф, чтобы рейд собирался при загрузке системы
Повысим привелегии до рута
```
[vagrant@otuslinux ~]$ sudo su -
```
Посмотрим детальную информацию о массиве
```
[root@otuslinux ~]# mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid5 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=3d6f0079:eb31680b:32ffdc79:ff1ff690
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde
```
Из документации по mdadm конфигурация находится в /etc/mdadm.conf  
Внесем данные по конфигурации в /etc/mdadm.conf
```
[root@otuslinux ~]# mdadm --detail --scan --verbose| awk '/ARRAY/ {print}'>> /etc/mdadm.conf
[root@otuslinux ~]#
```
проверим /etc/mdadm.conf
```
[root@otuslinux ~]# cat /etc/mdadm.conf
ARRAY /dev/md0 level=raid5 num-devices=4 metadata=1.2 name=otuslinux:0 UUID=3d6f0079:eb31680b:32ffdc79:ff1ff690
[root@otuslinux ~]#
```
## Авария массива
Сломаем RAID выведем один из дисков из массива, например `/dev/sdd`
```
[root@otuslinux ~]# mdadm /dev/md0 --fail /dev/sdd
mdadm: set /dev/sdd faulty in /dev/md0
[root@otuslinux ~]#
```
Проверим состояние массива
```
[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid5 sde[4] sdd[2](F) sdc[1] sdb[0]
      761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [UU_U]

unused devices: <none>
[root@otuslinux ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Feb  9 09:39:52 2020
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Feb  9 10:03:16 2020
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 3d6f0079:eb31680b:32ffdc79:ff1ff690
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       -       0        0        2      removed
       4       8       64        3      active sync   /dev/sde

       2       8       48        -      faulty   /dev/sdd
[root@otuslinux ~]#
```
Массив находится в аварии:
```       Update Time : Sun Feb  9 10:03:16 2020
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 1
     Spare Devices : 0
```
извлечем диск `/dev/sdd` из массива
```
[root@otuslinux ~]# mdadm /dev/md0 --remove /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md0
[root@otuslinux ~]#
[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid5 sde[4] sdc[1] sdb[0]
      761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [UU_U]

unused devices: <none>
```
вернем диск `/dev/sdd` в массив
```
[root@otuslinux ~]# mdadm /dev/md0 --add /dev/sdd
mdadm: added /dev/sdd
[root@otuslinux ~]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid5 sdd[5] sde[4] sdc[1] sdb[0]
      761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]

unused devices: <none>
[root@otuslinux ~]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Feb  9 09:39:52 2020
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Sun Feb  9 10:09:56 2020
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 3d6f0079:eb31680b:32ffdc79:ff1ff690
            Events : 40

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       5       8       48        2      active sync   /dev/sdd
       4       8       64        3      active sync   /dev/sde
[root@otuslinux ~]#
```
Все диски массива находятся в рабочем состоянии
### Создать GPT раздел и 5 партиций

Создадим GPT раздел
```
[root@otuslinux ~]# parted -s /dev/md0 mklabel gpt
[root@otuslinux ~]#
```
Проверим созданный раздел
```
[root@otuslinux ~]# parted /dev/md0
GNU Parted 3.1
Using /dev/md0
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) p                                                                
Model: Linux Software RAID Array (md)
Disk /dev/md0: 780MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start  End  Size  File system  Name  Flags

(parted)                                                                  
(parted) q  
```
Создадим партиции:
```
[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 20% 40%        
Information: You may need to update /etc/fstab.

[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 40% 60%       
Information: You may need to update /etc/fstab.

[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 60% 80%       
Information: You may need to update /etc/fstab.

[root@otuslinux ~]# parted /dev/md0 mkpart primary ext4 80% 100%      
Information: You may need to update /etc/fstab.

[root@otuslinux ~]#    
```
Создадим файловые системы на ранее созданных партициях
однострочником:  
`for i in $(seq 1 5); do mkfs.ext4 /dev/md0p$i;done`
```
[root@otuslinux ~]# for i in $(seq 1 5); do mkfs.ext4 /dev/md0p$i;done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
37696 inodes, 150528 blocks
7526 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
1984 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
38152 inodes, 152064 blocks
7603 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
2008 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
38456 inodes, 153600 blocks
7680 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
2024 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
38152 inodes, 152064 blocks
7603 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
2008 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
37696 inodes, 150528 blocks
7526 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
1984 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

[root@otuslinux ~]#
```
Создадим точки монтирования однострочником  
`mkdir -p /raid/part{1,2,3,4,5}`
```
[root@otuslinux ~]# mkdir -p /raid/part{1,2,3,4,5}
```
Смонтируем созданные диски в точки монтирования однострочником  
`for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i;done`
```
[root@otuslinux ~]# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i;done
[root@otuslinux ~]#
```
Проверим смонтированные разделы:
```
[root@otuslinux ~]# ls -la /raid/
total 5
drwxr-xr-x.  7 root root   71 Feb  9 10:57 .
dr-xr-xr-x. 19 root root  267 Feb  9 10:57 ..
drwxr-xr-x.  3 root root 1024 Feb  9 10:46 part1
drwxr-xr-x.  3 root root 1024 Feb  9 10:46 part2
drwxr-xr-x.  3 root root 1024 Feb  9 10:46 part3
drwxr-xr-x.  3 root root 1024 Feb  9 10:46 part4
drwxr-xr-x.  3 root root 1024 Feb  9 10:46 part5
[root@otuslinux ~]#
[root@otuslinux ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        40G  3.9G   37G  10% /
devtmpfs        488M     0  488M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.7M  489M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
tmpfs           100M     0  100M   0% /run/user/1000
/dev/md0p1      139M  1.6M  127M   2% /raid/part1
/dev/md0p2      140M  1.6M  128M   2% /raid/part2
/dev/md0p3      142M  1.6M  130M   2% /raid/part3
/dev/md0p4      140M  1.6M  128M   2% /raid/part4
/dev/md0p5      139M  1.6M  127M   2% /raid/part5
[root@otuslinux ~]#
```
## Заключение
Все цели поставленные в задании выполненны.


# Lab6_proces
## **ДОМАШНЕЕ ЗАДАНИЕ**

### Задание 1 - Написать свою реализацию ps ax используя анализ /proc
Выполним команду: `ps ax` для получения верного вывода:
```bash
[root@ProcessLab ~]# ps ax
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:01 /usr/lib/systemd/systemd --switched-root --system --deserialize 21
    2 ?        S      0:00 [kthreadd]
...
```
Выведем ту же последовательность опций используя команду `ps -o ...` для процесса `PID 13329`:

```bash
[root@ProcessLab ~]# ps ax |grep 13329
 4322 pts/0    S+     0:00 grep --color=auto 13329
13329 ?        Ssl    0:00 /usr/sbin/NetworkManager --no-daemon
[root@ProcessLab ~]# ps -o pid,tname,stat,bsdtime,args 13329
  PID TTY      STAT   TIME COMMAND
13329 ?        Ssl    0:00 /usr/sbin/NetworkManager --no-daemon
[root@ProcessLab ~]#
```

Значение выбранных опций следующие:

| Значение  | Опция | Описание 
|---|---|---
| PID | pid | a number representing the process ID (alias tgid).
| TTY | tname | controlling tty (terminal).  (alias tt, tty).
| STAT | stat | multi-character process state.  See section PROCESS STATE CODES for the different values meaning.  See also s and state if you just want the first character displayed.
| TIME | bsdtime | accumulated cpu time, user + system.  The display format is usually "MMM:SS", but can be shifted to the right if the process used more than 999 minutes of cpu time.
| COMMAND | args | command with all its arguments as a string. Modifications to the arguments may be shown.  The output in this column may contain spaces.

Данные о запущенных процессах находятся в псевдофайловой системе `/proc`. Обратимся к документации `man proc`.  
Из описания ФС `proc` необходимые данные можем получать из файла `/proc/[pid]/stat` для каждого отдельного процесса. Структура предоставления данных описана там же.  
Пример для процесса `PID 133329`:

```bash
[root@ProcessLab ~]# cat -n /proc/13329/stat
     1  13329 (NetworkManager) S 1 13329 13329 0 -1 1077944576 3794 105 26 0 5 38 0 0 20 0 3 0 17027 561582080 409 18446744073709551615 94240022269952 94240025100393 140736609748944 140736609748352 140479180729405 0 0 4096 84483 18446744073709551615 0 0 17 0 0 0 6 0 0 94240027197552 94240027269664 94240034639872 140736609754994 140736609755031 140736609755031 140736609755103 0
```

Вывод файла `/proc/[pid]/stat`, это строка разделенная пробелом.
Получим `PID, TTY, STAT, TIME, COMMAND` awk из файла `/proc/[pid]/stat`.  

| Значение  | Опция | Поле `/proc/[pid]/stat`
|---|---|---|
| PID | pid | поле 1
| TTY | tname | поле 8
| STAT | stat |  поле 4
| TIME | bsdtime | поле ?
| COMMAND | args | Данные не содержатся в `/proc/[pid]/stat`, но присутствует в `/proc/[pid]/cmdline`
 
- 

```bash
[root@ProcessLab ~]# cat -n /proc/13329/cmdline
     1  /usr/sbin/NetworkManager--no-daemon
```

#### Определение количества работающих процессов:
Определим кличество процессов коммандой `ps`:

```bash
[vagrant@ProcessLab ~]$ ps ax| wc -l
85
```

Получим те же данные из `/proc`:

```bash
[vagrant@ProcessLab ~]$ ls /proc/ |grep -e [[:digit:]]|wc -l
85
[vagrant@ProcessLab ~]$
```

Проверим работу `grep` по `/proc`, запустим фоновый процесс `sleep 200 &`

```bash
[vagrant@ProcessLab ~]$ sleep 200 &
[1] 2935
[vagrant@ProcessLab ~]$ ps ax| wc -l
83
[vagrant@ProcessLab ~]$ ls /proc/ |grep -e [[:digit:]]|wc -l
83
[vagrant@ProcessLab ~]$
```

Проверим количество процессов после завершения фонового процесса:

```bash
[vagrant@ProcessLab ~]$ jobs
[1]+  Done                    sleep 200
[vagrant@ProcessLab ~]$ ps ax| wc -l
82
[vagrant@ProcessLab ~]$ ls /proc/ |grep -e [[:digit:]]|wc -l
82
```

Конструкция: `ls /proc/ |grep -e [[:digit:]]| wc -l` проводит подсчет процессов верно.


`awk '{print $1,$7,$3,$14+$15}' /proc/11971/stat`

```bash
[root@ProcessLab 2145]# awk '{print $1,$7,$3,$14+$15}' stat
2145 0 S 59
```

Выводим: ID, state,tty,time(utime+stime)



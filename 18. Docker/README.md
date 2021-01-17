# lab12_Docker
ДЗ Docker
## Задание.
### Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

Все действия будем проводить на виртуальной машине.  При развертывании `Docker` на CentOS 8 столкнулся с пролемой сборки образов. При провеке выяснил, что не установлся компонент `containerd.io`. Официальный репозиторий **ТОЛЬКО** для CentOS 7: https://download.docker.com/linux/centos/  
Ошибка установки пакета в CentOS 8:
```bash
Error:
 Problem: package docker-ce-3:19.03.9-3.el7.x86_64 requires containerd.io >= 1.2.2-3, but none of the providers can be installed
  - cannot install the best candidate for the job
  - package containerd.io-1.2.10-3.2.el7.x86_64 is excluded
  - package containerd.io-1.2.13-3.1.el7.x86_64 is excluded
  - package containerd.io-1.2.13-3.2.el7.x86_64 is excluded
  - package containerd.io-1.2.2-3.3.el7.x86_64 is excluded
  - package containerd.io-1.2.2-3.el7.x86_64 is excluded
  - package containerd.io-1.2.4-3.1.el7.x86_64 is excluded
  - package containerd.io-1.2.5-3.1.el7.x86_64 is excluded
  - package containerd.io-1.2.6-3.3.el7.x86_64 is excluded
```
После чего была рвзвернута ВМ на CentOS 7  
Проверим весию Docker в ВМ:
```bash
[root@localhost ~]# docker version
Client: Docker Engine - Community
 Version:           19.03.9
 API version:       1.40
 Go version:        go1.13.10
 Git commit:        9d988398e7
 Built:             Fri May 15 00:25:27 2020
 OS/Arch:           linux/amd64
 Experimental:      false
```
Версия Docker В хостовой машие:
```bash
[dkasyan@MyX240 lab12_Docker]$ docker --version
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.
podman version 1.6.4
```
Выполняем ДЗ в CentOS 7  

Просмотрим имеющиеся образы контейнеров:
```bash
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-world         latest              bf756fb1ae65        4 months ago        13.3kB
```
Скачаем последнюю версию образа `Alpine` и просмотрим список образов контейнеров:
```bash
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
alpine              latest              f70734b6a266        3 weeks ago         5.61MB
hello-world         latest              bf756fb1ae65        4 months ago        13.3kB
[root@localhost ~]#
```
Запустим контейнер и установим NGINX:
```bash
[root@localhost ~]# docker run -it alpine:latest
/ # apk update
fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/community/x86_64/APKINDEX.tar.gz
v3.11.6-46-gff7db7c636 [http://dl-cdn.alpinelinux.org/alpine/v3.11/main]
v3.11.6-40-g4ab6ec338e [http://dl-cdn.alpinelinux.org/alpine/v3.11/community]
OK: 11270 distinct packages available
/ # apk add nginx --no-cache
fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/community/x86_64/APKINDEX.tar.gz
(1/2) Installing pcre (8.43-r0)
(2/2) Installing nginx (1.16.1-r6)
Executing nginx-1.16.1-r6.pre-install
Executing busybox-1.31.1-r9.trigger
OK: 7 MiB in 16 packages
```

## Использованные материалы:
1. https://docs.docker.com/get-started/
1. https://docs.docker.com/engine/install/centos/#install-using-the-repository
1. https://github.com/yobasystems/alpine-nginx/tree/master/alpine-nginx-amd64
1. https://habr.com/ru/post/310460/#dockerfile

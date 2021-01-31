# Docker

## Задание - Dockerfile

- Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx). 
- Определите разницу между контейнером и образом. Вывод опишите в домашнем задании. 
- Ответьте на вопрос: Можно ли в контейнере собрать ядро? 

Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.

## Подготовка стенда

Установим `Docker` воспользовавшись официальной документацией: https://docs.docker.com/engine/install/centos/  
Выполним следующие команды:

```bash
yum remove docker*
yum install yum-utils -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io
yum list docker-ce --showduplicates | sort -r
systemctl enable docker
systemctl start docker
systemctl status docker
docker run hello-world
```

<details> <summary>Посмотрим вывод последних выполненных команд:</summary>

```bash
[root@DockerLab Docker_test]# systemctl start docker
[root@DockerLab Docker_test]# systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2021-01-29 03:04:29 UTC; 8s ago
     Docs: https://docs.docker.com
 Main PID: 14653 (dockerd)
    Tasks: 8
   Memory: 129.5M
   CGroup: /system.slice/docker.service
           └─14653 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.127162921Z" level=info msg="scheme \"unix\" not registered, fallback to...ule=grpc
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.127184809Z" level=info msg="ccResolverWrapper: sending update to cc: {[...ule=grpc
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.127196259Z" level=info msg="ClientConn switching balancer to \"pick_fir...ule=grpc
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.152268938Z" level=info msg="Loading containers: start."
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.314896633Z" level=info msg="Default bridge (docker0) is assigned with a...address"
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.377492009Z" level=info msg="Loading containers: done."
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.430051980Z" level=info msg="Docker daemon" commit=8891c58 graphdriver(s...=20.10.2
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.430224318Z" level=info msg="Daemon has completed initialization"
Jan 29 03:04:29 DockerLab systemd[1]: Started Docker Application Container Engine.
Jan 29 03:04:29 DockerLab dockerd[14653]: time="2021-01-29T03:04:29.469974040Z" level=info msg="API listen on /var/run/docker.sock"
Hint: Some lines were ellipsized, use -l to show in full.
[root@DockerLab Docker_test]# docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
0e03bdcc26d7: Pull complete
Digest: sha256:31b9c7d48790f0d8c50ab433d9c3b7e17666d6993084c002c2ff1ca09b96391d
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

</details>

Докер успешно стартовал. Скачан образ `hello-world` и запущен контейнер.  
Настройка стенда завершена.

## Сборка кастомного образа 

Для сборки воспользуемся дистрибутивом [Alpine Linux](https://alpinelinux.org/) версией 3.13.0

Для верной работы подготовим:  
 - [Стартовую страницу](alpine-nginx/files/index.html)
 - [Конфигурационный файл NGINX](alpine-nginx/files/nginx.conf)

[Создадим Dockerfile](alpine-nginx/Dockerfile)  

**Важный момент.**  
В конфигурации NGINX добавим директиву - `daemon off;`. при отсутствии данной директивы Nginx запускается как демон и команда `ENTRYPOINT ["nginx"]` не позволяет запустить уже запущеный демон. В итоге команда завершается и контейнер закрывается.  
Данную проблему можно решить без указания диретивы `daemon off;` в кофигурации `Nginx`, но команду для поднятия контейнера необходимо изменить на: `ENTRYPOINT ["nginx", "-g", "daemon off;"]`  
Информацию по запуску контейнера на основе Alpine нашел на официальном GIT [nginxinc/docker-nginx](https://github.com/nginxinc/docker-nginx/blob/41156d8a36bd03b2fb36353ba31f16ada08d9e48/mainline/alpine/Dockerfile)


<details><summary>Соберем образ и запустим контейнер из подготовленного Dockerfile</summary>

```bash
[root@DockerLab alpine-nginx]# docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
[root@DockerLab alpine-nginx]# docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
[root@DockerLab alpine-nginx]# docker build -t alpine-nginx:1.0 .
Sending build context to Docker daemon  7.168kB
Step 1/9 : FROM alpine:3.13.0
3.13.0: Pulling from library/alpine
596ba82af5aa: Pull complete
Digest: sha256:d9a7354e3845ea8466bb00b22224d9116b183e594527fb5b6c3d30bc01a20378
Status: Downloaded newer image for alpine:3.13.0
 ---> 7731472c3f2a
Step 2/9 : RUN apk add --no-cache nginx
 ---> Running in 2661fe8edc4c
fetch https://dl-cdn.alpinelinux.org/alpine/v3.13/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.13/community/x86_64/APKINDEX.tar.gz
(1/2) Installing pcre (8.44-r0)
(2/2) Installing nginx (1.18.0-r13)
Executing nginx-1.18.0-r13.pre-install
Executing nginx-1.18.0-r13.post-install
Executing busybox-1.32.1-r0.trigger
OK: 7 MiB in 16 packages
Removing intermediate container 2661fe8edc4c
 ---> 18b6d1c23e58
Step 3/9 : RUN adduser -D -g 'www' www
 ---> Running in 3054a928e6a2
Removing intermediate container 3054a928e6a2
 ---> 14e4fa1a2eb9
Step 4/9 : RUN mkdir -p /run/nginx && mkdir -p /www
 ---> Running in f78bb3421165
Removing intermediate container f78bb3421165
 ---> 16b3b6a8c142
Step 5/9 : RUN chown -R www:www /var/lib/nginx && chown -R www:www /www
 ---> Running in 71c2b8efd707
Removing intermediate container 71c2b8efd707
 ---> e1cde83cab8d
Step 6/9 : COPY files/index.html /www
 ---> d2c271ef1e1f
Step 7/9 : COPY files/nginx.conf /etc/nginx/nginx.conf
 ---> 2b2f742deb9e
Step 8/9 : EXPOSE 80 443
 ---> Running in 520f90788c87
Removing intermediate container 520f90788c87
 ---> b1e66b4a2834
Step 9/9 : ENTRYPOINT ["nginx"]
 ---> Running in 818fec1d45bd
Removing intermediate container 818fec1d45bd
 ---> 0ed02df6b72c
Successfully built 0ed02df6b72c
Successfully tagged alpine-nginx:1.0
[root@DockerLab alpine-nginx]# docker images
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
alpine-nginx   1.0       0ed02df6b72c   34 seconds ago   7.04MB
alpine         3.13.0    7731472c3f2a   2 weeks ago      5.61MB
[root@DockerLab alpine-nginx]# docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
[root@DockerLab alpine-nginx]# docker run -it -d -p 8000:80 alpine-nginx:1.0
648dc847ecdf6e443a48030422e3d4fde7aa2333a5419cdc79e146ae6fa49c99
[root@DockerLab alpine-nginx]# docker ps
CONTAINER ID   IMAGE              COMMAND   CREATED         STATUS         PORTS                           NAMES
648dc847ecdf   alpine-nginx:1.0   "nginx"   5 seconds ago   Up 4 seconds   443/tcp, 0.0.0.0:8000->80/tcp   dazzling_babbage
[root@DockerLab alpine-nginx]# docker ps -a
CONTAINER ID   IMAGE              COMMAND   CREATED          STATUS          PORTS                           NAMES
648dc847ecdf   alpine-nginx:1.0   "nginx"   11 seconds ago   Up 10 seconds   443/tcp, 0.0.0.0:8000->80/tcp   dazzling_babbage
[root@DockerLab alpine-nginx]# curl localhost:8000
<!DOCTYPE html>
<html>
  <head>
    <title>This is alpine-nginx</title>
    <style>
      body {width: 35em;margin: 0 auto;font-family: Tahoma, Verdana, Arial, sans-serif;}
    </style>
  </head>
  <body>
    <h1>This is alpine-nginx</h1>
    <p>If you see this page, the nginx web server is successfully installed and working. Further configuration is required.</p>
    <p><em>Thank you for using alpine-nginx.</em></p>
  </body>
</html>
[root@DockerLab alpine-nginx]#
```

</details>

Из вывода, видим. Образ создался, запуск прошел успешно. Web страница отдается.

## Разница между контейнером и образом

**Образ** - создается Dockerfile'ом. В нем определяется устанавливаемый софт и конфигурационные файлы софта. Образ создается один раз.  

**Контейнер** - создается при выполнении команды `docker run`. Контейнер равершает свое существование при окончании своей работы. Из одого образа можно создать несколько однотипных контейнеров с разными параметрами.

## Можно ли в контейнере собрать ядро?

Контейнер предназначен для изоляции процессов используя технологии cgroups и namespace. Контейнер использует ядро ОС.  
Думаю, что собрать ядро теоретически возможно, так как выполняется `make` но возникает вопрос: **Зачем?**. Для сборки ядра больше подойдет технология виртулизации, чем контейниризации.

## Образ на Docker Hub

Изменим таг на созданный образ, используя зарегистрированный id на Docker Hub:
``` bash
[root@DockerLab alpine-nginx]# docker tag alpine-nginx:1.0 dkasyan/alpine-nginx:1.0
[root@DockerLab alpine-nginx]# docker images
REPOSITORY             TAG       IMAGE ID       CREATED          SIZE
dkasyan/alpine-nginx   1.0       0ed02df6b72c   58 minutes ago   7.04MB
alpine-nginx           1.0       0ed02df6b72c   58 minutes ago   7.04MB
alpine                 3.13.0    7731472c3f2a   2 weeks ago      5.61MB
```

Загрузим образ на Doker Hub:

``` bash
[root@DockerLab alpine-nginx]# docker login --username dkasyan
Password:
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
[root@DockerLab alpine-nginx]# docker push dkasyan/alpine-nginx:1.0
The push refers to repository [docker.io/dkasyan/alpine-nginx]
cba380482bd0: Pushed
38dcde89f639: Pushed
02ad3d7c6afc: Pushed
695d10f9a37d: Pushed
94d26e15c73d: Pushed
2cf4b7b8424d: Pushed
c04d1437198b: Mounted from library/alpine
1.0: digest: sha256:908a1bb76524f16156c452e5342316bb899db9d7ba5eb42385f94f6057400113 size: 1774
```
Образ доступен по ссылке: https://hub.docker.com/repository/docker/dkasyan/alpine-nginx

# Ход выполнения домашнего задания
Во время выполнения ДЗ сложностей не возникло.
Файл конфигурации NGINX находился по пути /etc/nginx/nginx.conf.  После внесения директивы `autoindex` в секцию:
```bash
location / {
root /usr/share/nginx/html;
index index.html index.htm;
autoindex on; Добавили эту директиву
}
```
Был получен доступ к размещенному репозиторию по http

Образ лабораторной машины собран в отдельный box-файл и загружен на Vgrant cloud  
[otuslab_yum](https://app.vagrantup.com/dkasyan/boxes/otuslab_yum "Ссылка на образ")

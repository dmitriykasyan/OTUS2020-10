# Выбираем образ
FROM alpine:3.13.0 

# Устанавливаем NGINX
RUN apk add --no-cache nginx    
# Создаем директории
RUN adduser -D -g 'www' www 
# Создаем пользователя
RUN mkdir -p /run/nginx && mkdir -p /www  
# Применяем права к директориям
RUN chown -R www:www /var/lib/nginx && chown -R www:www /www 

# Копируем подготовленные файлы страницы и конфигурации
COPY files/index.html /www  
COPY files/nginx.conf /etc/nginx/nginx.conf

# VOLUME ["/var/cache/nginx"]

EXPOSE 80 443 

# Запускаем NGINX
# ENTRYPOINT ["nginx", "-g", "daemon off;"]
ENTRYPOINT ["nginx"]  

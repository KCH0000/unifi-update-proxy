FROM nginx:1.24-alpine

# Создаем директории
RUN mkdir -p /etc/nginx/stream.conf.d

# Копируем конфигурационные файлы
COPY nginx.conf /etc/nginx/nginx.conf
COPY stream.conf.d/ /etc/nginx/stream.conf.d/

# Открываем порт для прокси
EXPOSE 443

# Запускаем NGINX в foreground
CMD ["nginx", "-g", "daemon off;"]

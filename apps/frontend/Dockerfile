FROM nginx:1.25-alpine

ENV BACKEND_SERVICE_HOST=backend \
    BACKEND_SERVICE_PORT=8080

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY public /usr/share/nginx/html

EXPOSE 80

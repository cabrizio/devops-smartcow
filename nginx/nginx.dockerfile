FROM nginx:1.17

RUN rm -rf /etc/nginx/conf.d/*
#ADD nginx//vhost.conf /etc/nginx/conf.d/default.conf
COPY nginx/config/vhost.conf /etc/nginx/conf.d/default.conf
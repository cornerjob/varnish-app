FROM ubuntu:latest

WORKDIR /var/service

ENV VARNISH_PORT 80
ENV NGINX_PORT 8080
ENV NGINX_PORT_SSL 433

COPY ./ /var/service/
COPY package.json /tmp/package.json

RUN chmod +x /var/service/start.sh && \
    apt update && \
    apt install -y build-essential git nodejs npm automake pkg-config libtool \
        python-docutils libvarnishapi-dev varnish nginx && \
    apt clean && \
    cd /tmp && npm install && \
    cp -a /tmp/node_modules /var/service/

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default /etc/nginx/sites-available/default
COPY varnish/varnish /etc/default/varnish
COPY varnish/default.vcl /etc/varnish/default.vcl

EXPOSE 8080 80 433

CMD /var/service/start.sh

FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl gettext-base \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /run/nginx

COPY conf/nginx.conf.template /etc/nginx/templates/nginx.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
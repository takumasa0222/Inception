#!/bin/sh
set -eu

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/server.crt ] || [ ! -f /etc/nginx/ssl/server.key ]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/server.key \
        -out /etc/nginx/ssl/server.crt \
        -subj "/CN=${DOMAIN_NAME}"
fi

envsubst '${DOMAIN_NAME}' \
    < /etc/nginx/templates/nginx.conf.template \
    > /etc/nginx/nginx.conf

nginx -t

exec nginx -g "daemon off;"
#!/bin/sh

set -eu  #コマンドが失敗したらその時点でスクリプト終了・未定義変数を使用したらエラー

WP_PATH="/var/www/html"
MYSQL_HOST="${MYSQL_HOST:-mariadb}" #環境変数が設定されていなければ一時的にデフォルト値を使用
MYSQL_PORT="${MYSQL_PORT:-3306}"
WP_URL="${WP_URL:-https://${DOMAIN_NAME}}"
WP_TITLE="${WP_TITLE:-Inception wordPress}"

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
: "${WP_USER:?WP_USER is required}"
: "${WP_USER_PASSWORD:?WP_USER_PASSWORD is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

mkdir -p /run/php
mkdir -p "$WP_PATH"

echo "Waiting for MariaDB..."

i=0
until MYSQL_PWD="$MYSQL_PASSWORD" mariadb \
    -h "$MYSQL_HOST" \
    -P "$MYSQL_PORT" \
    -u "$MYSQL_USER" \
    "$MYSQL_DATABASE" \
    -e "SELECT 1;" >/dev/null 2>&1
do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
        echo "Error: MariaDB is not ready after 60 seconds."
        exit 1
    fi
    sleep 1
done

echo "MariaDB is ready."

cd "$WP_PATH"

if [ ! -f "$WP_PATH/wp-load.php" ]; then
    echo "Downloading WordPress..."
    wp core download \
        --path="$WP_PATH" \
        --allow-root
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --path="$WP_PATH" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="${MYSQL_HOST}:${MYSQL_PORT}" \
        --allow-root
fi

if ! wp core is-installed --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
    echo "Installing WordPress..."
    wp core install \
        --path="$WP_PATH" \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi

if ! wp user get "$WP_USER" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
    echo "Creating normal WordPress user..."
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --path="$WP_PATH" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
fi

chown -R www-data:www-data "$WP_PATH"

echo "Starting php-fpm..."
exec "$@"
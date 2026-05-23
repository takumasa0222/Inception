#!/bin/bash
set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

echo "[DEBUG] entrypoint started"
echo "[DEBUG] MYSQL_DATABASE=${MYSQL_DATABASE:-unset}"
echo "[DEBUG] MYSQL_USER=${MYSQL_USER:-unset}"

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

echo "[DEBUG] checking /var/lib/mysql"
ls -la /var/lib/mysql || true

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[DEBUG] /var/lib/mysql/mysql does not exist"
    echo "[DEBUG] Running first-time MariaDB initialization"
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    mariadbd --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &

    pid="$!"

    until mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent; do
        sleep 1
    done

    mariadb --socket=/run/mysqld/mysqld.sock << EOF
DELETE FROM mysql.user WHERE User = '';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db = 'test' OR Db LIKE 'test\\_%';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    mariadb-admin --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "$pid"
fi

exec "$@"
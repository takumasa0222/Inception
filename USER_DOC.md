# User Documentation

## Overview

This document explains how to use and operate the Inception stack as an end user or administrator.

The stack provides a local HTTPS WordPress website powered by three Docker containers:

- **NGINX**: receives HTTPS requests from the browser.
- **WordPress + php-fpm**: runs the WordPress application.
- **MariaDB**: stores WordPress data such as posts, users, settings, and comments.

The public website is available at:

```text
https://tamatsuu.42.fr
```

The WordPress administration panel is available at:

```text
https://tamatsuu.42.fr/wp-admin
```

## Provided Services

### NGINX

NGINX is the only service directly reachable from the host machine.

It listens on port `443` and uses TLS. It forwards PHP requests to the WordPress php-fpm container.

### WordPress

WordPress provides the website and the administration panel.

It is not directly exposed to the host. It communicates with NGINX and MariaDB through the Docker network.

### MariaDB

MariaDB stores the WordPress database.

It is not directly exposed to the host. Only the WordPress container should connect to it.

## Start the Project

From the repository root, run:

```bash
make
```

or:

```bash
make up
```

Then check that all containers are running:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Expected services:

```text
nginx
wordpress
mariadb
```

## Stop the Project

To stop the containers without deleting persistent data:

```bash
make down
```

The WordPress website files and database remain stored in Docker named volumes.

## Restart the Project

```bash
make down
make up
```

or:

```bash
make re
```

Depending on the Makefile implementation, `make re` may rebuild the images before starting the stack again.

## Access the Website

Open this URL in a browser:

```text
https://tamatsuu.42.fr
```

If the browser shows a warning about the certificate, this is expected because the project uses a local self-signed certificate.

Proceed only if you are accessing your own local VM/project.

## Access the Administration Panel

Open:

```text
https://tamatsuu.42.fr/wp-admin
```

Use the WordPress administrator credentials configured during setup.

Important: according to the project rules, the administrator username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.

## Credentials

Credentials are stored locally and must not be committed to Git.

Typical credential files are located under:

```text
secrets/
```

Common files:

| File | Purpose |
|---|---|
| `db_root_password.txt` | MariaDB root password |
| `db_password.txt` | Password for the MariaDB WordPress user |
| `wp_admin_password.txt` | Password for the WordPress admin |
| `wp_user_password.txt` | Password for the WordPress user |

To check whether the secret files exist:

```bash
ls -al secrets
```

To confirm that a secret file is not empty:

```bash
test -s secrets/db_password.txt && echo "db_password exists"
test -s secrets/db_root_password.txt && echo "db_root_password exists"
test -s secrets/wp_admin_password.txt && echo "wp_admin_password exists"
test -s secrets/wp_user_password.txt && echo "wp_user_password exists"
```

Do not print passwords to the terminal unless absolutely necessary.

## Check Service Health

### Check Containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

All mandatory services should be listed and running.

### Check Logs

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Useful things to look for:

- NGINX starts without TLS or configuration errors.
- WordPress php-fpm starts and listens internally.
- MariaDB initializes and accepts connections.
- No container repeatedly exits or restarts.

### Check HTTPS

From the host or VM:

```bash
curl -k -I https://tamatsuu.42.fr
```

A successful result usually includes an HTTP status such as:

```text
HTTP/1.1 200 OK
```

or a redirect such as:

```text
HTTP/1.1 301 Moved Permanently
```

### Check TLS Version

```bash
openssl s_client -connect tamatsuu.42.fr:443 -tls1_2
```

or:

```bash
openssl s_client -connect tamatsuu.42.fr:443 -tls1_3
```

TLS 1.2 or TLS 1.3 should work, depending on the NGINX configuration.

### Check WordPress to MariaDB Connection

From the WordPress container:

```bash
docker compose -f srcs/docker-compose.yml exec wordpress sh
```

Then, depending on installed tools, verify the database settings or use WP-CLI if available:

```bash
wp db check --allow-root
```

If WP-CLI is not installed, check WordPress logs and confirm that the website loads in the browser.

## Persistent Data

The project uses Docker named volumes for persistent storage.

Expected volumes:

```text
mariadb_data
wordpress_data
```

Check them with:

```bash
docker volume ls
docker volume inspect mariadb_data
docker volume inspect wordpress_data
```

The project stores volume data under:

```text
/home/tamatsuu/data
```

Typical host-side directories:

```text
/home/tamatsuu/data/mariadb
/home/tamatsuu/data/wordpress
```

Do not manually delete these directories unless you intentionally want to remove the website and database data.

## Common Operations

### View All Logs

```bash
docker compose -f srcs/docker-compose.yml logs
```

### Follow Logs in Real Time

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

### Restart One Service

```bash
docker compose -f srcs/docker-compose.yml restart nginx
docker compose -f srcs/docker-compose.yml restart wordpress
docker compose -f srcs/docker-compose.yml restart mariadb
```

### Enter a Container

```bash
docker compose -f srcs/docker-compose.yml exec nginx sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

## Troubleshooting

### The Website Does Not Open

Check:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Then check NGINX logs:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
```

Also confirm that the domain points to the local machine:

```bash
grep tamatsuu.42.fr /etc/hosts
```

### Browser Shows a Certificate Warning

This is expected when using a self-signed certificate.

For the local project, continue only if the URL is your own configured domain:

```text
https://tamatsuu.42.fr
```

### WordPress Shows a Database Error

Check that MariaDB is running:

```bash
docker compose -f srcs/docker-compose.yml ps mariadb
```

Check MariaDB logs:

```bash
docker compose -f srcs/docker-compose.yml logs mariadb
```

Check WordPress logs:

```bash
docker compose -f srcs/docker-compose.yml logs wordpress
```

Also verify that the database name, database user, and secret files match the `.env` configuration.

### Data Disappeared

Check whether the named volumes still exist:

```bash
docker volume ls
```

Check whether the host data directory still exists:

```bash
ls -al /home/tamatsuu/data
```

If `make fclean` or a manual volume removal was executed, the persistent data may have been deleted.

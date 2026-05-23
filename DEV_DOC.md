# Developer Documentation

## Overview

This document explains how to set up, build, run, inspect, and maintain the Inception project from a developer perspective.

The project is built with Docker Compose and contains the mandatory services:

- `nginx`
- `wordpress`
- `mariadb`

Each service has its own Dockerfile and runs in its own container.

## Prerequisites

Use a Linux virtual machine with:

- Docker Engine
- Docker Compose plugin
- GNU Make
- OpenSSL
- Git
- basic shell tools such as `sh`, `ls`, `grep`, `cat`, and `test`

Check Docker:

```bash
docker --version
docker compose version
```

Check Make:

```bash
make --version
```

## Repository Layout

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── wp_admin_password.txt
|   ├── wp_user_password.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

## Environment Setup From Scratch

### 1. Clone the Repository

```bash
git clone <repository-url> inception
cd inception
```

### 2. Create Host Data Directories

The named volumes must store their data under:

```text
/home/tamatsuu/data
```

Create the required directories:

```bash
mkdir -p /home/tamatsuu/data/mariadb
mkdir -p /home/tamatsuu/data/wordpress
```

If permission issues occur, adjust ownership for your user:

```bash
sudo chown -R "$USER:$USER" /home/tamatsuu/data
```

### 3. Configure Local Domain

Add the domain to `/etc/hosts`:

```bash
sudo sh -c 'echo "127.0.0.1 tamatsuu.42.fr" >> /etc/hosts'
```

If the project runs inside a VM and the browser is on the host OS, use the VM IP instead of `127.0.0.1`.

### 4. Create `.env`

Create:

```text
srcs/.env
```

Example:

```env
DOMAIN_NAME=tamatsuu.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

WORDPRESS_DB_HOST=mariadb
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wp_user

WP_TITLE=Inception
WP_URL=https://tamatsuu.42.fr
WP_ADMIN_USER=owner
WP_ADMIN_EMAIL=owner@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com
```

Keep sensitive values out of `.env`.

### 5. Create Secrets

Create the `secrets` directory:

```bash
mkdir -p secrets
```

Create required secret files:

```bash
printf '%s
' '<root-password>' > secrets/db_root_password.txt
printf '%s
' '<database-user-password>' > secrets/db_password.txt
printf '%s
' '<wp_admin_password>' > secrets/wp_admin_password.txt
printf '%s
' '<wp_user_password>' > secrets/wp_user_password.txt
```


Set restrictive permissions:

```bash
chmod 600 secrets/*.txt
```

Make sure secrets are ignored by Git:

```bash
git check-ignore secrets/db_password.txt
git check-ignore secrets/db_root_password.txt
git check-ignore secrets/wp_admin_password.txt
git check-ignore secrets/wp_user_password.txt
```

## Build and Launch

### Using Makefile

Build and start the full stack:

```bash
make
```

or:

```bash
make up
```

Common Makefile targets:

| Target | Purpose |
|---|---|
| `make` / `make up` | Build and start the stack |
| `make down` | Stop and remove containers and network |
| `make clean` | Stop the stack and remove project containers/images depending on implementation |
| `make fclean` | Remove containers, images, volumes, and persistent data depending on implementation |
| `make re` | Rebuild from a clean state |

### Using Docker Compose Directly

Build:

```bash
docker compose -f srcs/docker-compose.yml build
```

Start:

```bash
docker compose -f srcs/docker-compose.yml up -d
```

Stop:

```bash
docker compose -f srcs/docker-compose.yml down
```

## Container Management Commands

### List Containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

### View Logs

```bash
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Follow Logs

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

### Enter Containers

```bash
docker compose -f srcs/docker-compose.yml exec nginx sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

### Restart Services

```bash
docker compose -f srcs/docker-compose.yml restart nginx
docker compose -f srcs/docker-compose.yml restart wordpress
docker compose -f srcs/docker-compose.yml restart mariadb
```

## Volume and Data Persistence

The project uses two named volumes:

| Volume | Purpose | Host storage |
|---|---|---|
| `mariadb_data` | MariaDB database files | `/home/tamatsuu/data/mariadb` |
| `wordpress_data` | WordPress website files | `/home/tamatsuu/data/wordpress` |

Check volumes:

```bash
docker volume ls
```

Inspect volumes:

```bash
docker volume inspect mariadb_data
docker volume inspect wordpress_data
```

Check host data:

```bash
ls -al /home/tamatsuu/data
ls -al /home/tamatsuu/data/mariadb
ls -al /home/tamatsuu/data/wordpress
```

Important: stopping containers with `docker compose down` does not remove named volumes unless `-v` is used.

## Network

The services communicate through a dedicated Docker network.

Expected communication path:

```text
Browser
  |
  | HTTPS :443
  v
nginx
  |
  | FastCGI :9000
  v
wordpress
  |
  | MariaDB :3306
  v
mariadb
```

Only NGINX should expose a host port.

Check networks:

```bash
docker network ls
docker network inspect <network-name>
```

## Validation Checklist

### Build Validation

```bash
make re
```

Confirm that the full project can be rebuilt from scratch.

### Container Validation

```bash
docker compose -f srcs/docker-compose.yml ps
```

Expected:

- `nginx` is running.
- `wordpress` is running.
- `mariadb` is running.

### Port Validation

Only port `443` should be exposed to the host.

```bash
docker compose -f srcs/docker-compose.yml ps
```

or:

```bash
ss -tulpen | grep 443
```

### TLS Validation

```bash
openssl s_client -connect tamatsuu.42.fr:443 -tls1_2
```

or:

```bash
openssl s_client -connect tamatsuu.42.fr:443 -tls1_3
```

### Website Validation

```bash
curl -k -I https://tamatsuu.42.fr
```

Expected result:

- HTTP response is returned.
- NGINX responds over HTTPS.
- WordPress page is accessible from a browser.

### WordPress Admin Validation

Open:

```text
https://tamatsuu.42.fr/wp-admin
```

Confirm that the configured WordPress administrator can sign in.

### MariaDB Validation

Enter the MariaDB container:

```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

If the MariaDB client is available:

```bash
mariadb -u root -p
```

Useful SQL checks:

```sql
SHOW DATABASES;
SELECT User, Host, plugin FROM mysql.user;
```

Check databases
```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh -c '
mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "
SHOW DATABASES;
"
'
```

Check User
```bash
docker compose -f srcs/docker-compose.yml exec mariadb sh -c '
mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "
SELECT User, Host, plugin FROM mysql.user
WHERE User = '\'''\'' OR User = '\''${MYSQL_USER}'\'';
"'
```

### WordPress Database Connection Validation

If WP-CLI is installed in the WordPress container:

```bash
docker compose -f srcs/docker-compose.yml exec wordpress wp db check --allow-root
```

If WP-CLI is not installed, validate by:

- opening the website,
- checking WordPress logs,
- checking MariaDB logs,
- confirming database tables were created.

## Troubleshooting Guide

### Container Exits Immediately

Check logs:

```bash
docker compose -f srcs/docker-compose.yml logs <service-name>
```

Common causes:

- missing environment variable,
- missing secret file,
- invalid config file,
- daemon not running in the foreground,
- permission issue in mounted volume.

### MariaDB Socket Error

An error such as:

```text
Can't connect to local server through socket '/run/mysqld/mysqld.sock'
```

usually means the MariaDB server process is not running or the client is trying to connect through a local socket instead of TCP.

Inside Docker, WordPress should connect to MariaDB using the service name:

```text
mariadb
```

not `localhost`.

### WordPress Cannot Connect to Database

Check:

```bash
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Verify:

- `MYSQL_DATABASE` matches `WORDPRESS_DB_NAME`.
- `MYSQL_USER` matches `WORDPRESS_DB_USER`.
- the database password secret is mounted and readable.
- MariaDB has completed initialization.
- WordPress uses `mariadb` as the database host.

### NGINX Cannot Reach WordPress

Check NGINX configuration:

```bash
docker compose -f srcs/docker-compose.yml exec nginx nginx -t
```

Check that the upstream points to:

```text
wordpress:9000
```

Check WordPress php-fpm logs:

```bash
docker compose -f srcs/docker-compose.yml logs wordpress
```

### Domain Does Not Resolve

Check `/etc/hosts`:

```bash
grep tamatsuu.42.fr /etc/hosts
```

Check DNS resolution:

```bash
getent hosts tamatsuu.42.fr
```

### Volume Data Is Not Persisting

Check the volume configuration in `srcs/docker-compose.yml`.

Check volume inspect output:

```bash
docker volume inspect mariadb_data
docker volume inspect wordpress_data
```

Check host path:

```bash
find /home/tamatsuu/data -maxdepth 2 -type d -print
```

## Development Notes

### Dockerfile Rule

Each service must have its own Dockerfile.

The project should build service images locally instead of pulling ready-made NGINX, WordPress, or MariaDB images.

Using Debian or Alpine as the base image is acceptable.

### Latest Tag Rule

Do not use the `latest` tag for base images.

Use a specific stable tag instead.

### PID 1 and Foreground Processes

A container should run the main service process in the foreground.

Do not keep containers alive with artificial infinite loops such as:

```bash
tail -f
sleep infinity
while true
```

### Password Rule

Do not write passwords in:

- Dockerfiles,
- shell scripts,
- committed `.env` files,
- committed documentation examples with real values.

Use secrets for confidential values.

## Git Hygiene

Recommended `.gitignore` entries:

```gitignore
secrets/*.txt
srcs/.env
*.log
.DS_Store
```

If an example environment file is useful, commit a sanitized template instead:

```text
srcs/.env.example
```

Do not commit real passwords, API keys, or credentials.

## Final Reproducibility Test

Before submission, run:

```bash
make fclean
make
```

Then verify:

```bash
docker compose -f srcs/docker-compose.yml ps
curl -k -I https://tamatsuu.42.fr
docker volume ls
ls -al /home/tamatsuu/data
```

The goal is to confirm that another evaluator can rebuild and run the project from the repository, local configuration, and secrets.

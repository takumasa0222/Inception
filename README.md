*This project has been created as part of the 42 curriculum by tamatsuu.*

# Inception

## Description

Inception is a system administration project that builds a small WordPress infrastructure using Docker Compose.

The project runs three mandatory services, each in its own container:

- **NGINX**: the only public entry point, exposed through HTTPS on port `443`.
- **WordPress + php-fpm**: runs WordPress application code without NGINX.
- **MariaDB**: stores the WordPress database without NGINX.

The goal is not only to make WordPress work, but also to understand how Docker images, containers, networks, volumes, environment variables, and secrets cooperate to form a reproducible infrastructure.

## Project Structure

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

## Services

| Service | Role | Internal port | Public access |
|---|---|---:|---|
| `nginx` | TLS reverse proxy | `443` | Yes, `https://tamatsuu.42.fr` |
| `wordpress` | WordPress with php-fpm | `9000` | No |
| `mariadb` | WordPress database | `3306` | No |

Only the `nginx` container publishes a host port. WordPress and MariaDB communicate through the Docker network only.

## Main Design Choices

### Virtual Machines vs Docker

A virtual machine runs a complete guest operating system on top of a hypervisor. It is strongly isolated, but heavier and slower to start.

Docker containers share the host kernel and isolate processes using Linux features such as namespaces and cgroups. They are lighter, faster to rebuild, and well suited for splitting one application into multiple services.

In this project, Docker is used to run each service separately while keeping the stack reproducible through Dockerfiles and Docker Compose.

### Secrets vs Environment Variables

Environment variables are useful for non-sensitive configuration such as domain names, database names, and usernames.

Secrets are better suited for sensitive values such as passwords. They are mounted as files inside containers, which avoids hardcoding passwords in Dockerfiles or committing them to Git.

This project uses:

- `.env` for general configuration.
- `secrets/` files for confidential values such as database passwords and WordPress credentials.

### Docker Network vs Host Network

A Docker network provides service discovery and isolation between containers. Containers can communicate using service names such as `mariadb` or `wordpress`.

The host network would remove much of this isolation and expose services more directly on the host. It is not used here.

This project uses a dedicated Docker network so that:

- NGINX can reach WordPress by service name.
- WordPress can reach MariaDB by service name.
- MariaDB is not exposed directly to the host.

### Docker Volumes vs Bind Mounts

Docker named volumes are managed by Docker and are suitable for persistent container data.

Bind mounts directly map a host directory into a container. They are useful during development, but they expose more host filesystem details and are not allowed for the mandatory persistent WordPress and MariaDB data in this project.

This project uses two named volumes:

- `mariadb_data`: stores MariaDB database files.
- `wordpress_data`: stores WordPress website files.

Both volumes are configured to store their data under `/home/tamatsuu/data` on the host machine.

## Instructions

### Prerequisites

The project is expected to be run inside a Linux virtual machine with:

- Docker
- Docker Compose plugin
- `make`
- OpenSSL
- permission to edit `/etc/hosts`

### Hostname Setup

Add the project domain to `/etc/hosts`:

```bash
sudo sh -c 'echo "127.0.0.1 tamatsuu.42.fr" >> /etc/hosts'
```

If your VM uses another reachable IP address, replace `127.0.0.1` with that IP.

### Configuration

Create or verify the configuration file:

```bash
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

Do not store passwords directly in `.env`.

### Secrets

Create the required secret files under `secrets/`:

```text
secrets/
├── wp_admin_password.txt
├── wp_user_password.txt
├── db_password.txt
└── db_root_password.txt
```

Example purpose of each file:

| File | Purpose |
|---|---|
| `db_root_password.txt` | MariaDB root password |
| `db_password.txt` | MariaDB password for the WordPress database user |
| `wp_admin_password.txt` | WordPress admin credentials used during setup |
| `wp_user_password.txt` | WordPress user credentials used during setup |

These files must not be committed to Git.

### Build and Start

From the repository root:

```bash
make
```

or explicitly:

```bash
make up
```

### Stop

```bash
make down
```

### Rebuild From Scratch

```bash
make re
```

### Clean Docker Resources Created by This Project

```bash
make clean
```

### Remove Persistent Data

Use this only when you intentionally want to delete the WordPress site and database data:

```bash
make fclean
```

## Usage

Open the WordPress site:

```text
https://tamatsuu.42.fr
```

Open the WordPress admin panel:

```text
https://tamatsuu.42.fr/wp-admin
```

Because the project uses a self-signed certificate, the browser may show a certificate warning. This is expected in a local development environment.

## Useful Commands

Check running containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

View logs:

```bash
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Enter a container:

```bash
docker compose -f srcs/docker-compose.yml exec nginx sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

Check volumes:

```bash
docker volume ls
docker volume inspect mariadb_data
docker volume inspect wordpress_data
```

Check the host storage path:

```bash
ls -al /home/tamatsuu/data
```

## Resources

### Official Documentation

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Docker storage volumes: https://docs.docker.com/engine/storage/volumes/
- Docker secrets in Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- NGINX documentation: https://nginx.org/en/docs/
- WordPress documentation: https://wordpress.org/documentation/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/

### AI Usage

AI was used as a learning and documentation assistant for this project.

Specifically, AI helped with:

- Organizing the project steps.
- Explaining Docker, TLS, NGINX, MariaDB, WordPress, and named volume concepts.
- Drafting documentation structure.
- Reviewing command examples and validation checks.
- Improving clarity of explanations.

AI-generated content was reviewed, adjusted, and tested manually. The final responsibility for understanding and maintaining the project remains with the project author.

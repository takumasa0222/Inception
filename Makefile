# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: tamatsuu <tamatsuu@student.42tokyo.jp>     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/05/23 05:51:07 by tamatsuu          #+#    #+#              #
#    Updated: 2026/05/23 16:41:27 by tamatsuu         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME		= inception

COMPOSE_FILE	= srcs/docker-compose.yml
ENV_FILE	= srcs/.env

LOGIN		= $(shell whoami)
DATA_DIR	= /home/$(LOGIN)/data
DB_DIR		= $(DATA_DIR)/mariadb
WP_DIR		= $(DATA_DIR)/wordpress

COMPOSE		= docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE)

.PHONY: all up build down start stop restart ps logs clean fclean re dirs

all: up

dirs:
	mkdir -p $(DB_DIR)
	mkdir -p $(WP_DIR)

build: dirs
	$(COMPOSE) build

up: dirs
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v --rmi all --remove-orphans
	sudo rm -rf $(DATA_DIR)

re: fclean up
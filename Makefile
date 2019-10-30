app_name := sf
branch := master
repository :=
xdebug := false
kibana := false
os := $(shell uname)
directory := ~
ls_parent := $(shell ls -p ..)
ppwd := $(shell cd ../ && pwd)

# Include & Export all .env variables as environment variables.
ifneq ("$(wildcard .env)","")
 	include .env
    export
endif

help:
	@echo "${YELLOW}Usage:${NC} ${ORANGE}make ${NC}[TARGET]${NC}"
	@echo "${YELLOW}Docker Targets${NC}"
	@echo "  init            ${CYAN} Initialize env files and clone project directory.${NC}"
	@echo "  start           ${CYAN} Create and start containers.${NC}"
	@echo "  stop            ${CYAN} Stop and clear all services.${NC}"
	@echo "  clean           ${CYAN} Clean directories for reset.${NC}"
	@echo "  restart         ${CYAN} Restart containers.${NC}"
	@echo "  housekeep       ${CYAN} Prune docker images/volumes/networks.${NC}"
	@echo "  logs            ${CYAN} Follow containers output logs.${NC}"
	@echo "${YELLOW}Project Targets${NC}"
	@echo "  checkout        ${CYAN} Checkout a branch.${NC}"
	@echo "  update          ${CYAN} Update packages.${NC}"
	@echo "  switch          ${CYAN} Switch between projects.${NC}"
	@echo "  encore          ${CYAN} Build Encore.${NC}"
	@echo "  cc              ${CYAN} Clear App/Doctrine caches.${NC}"
	@echo "  php-cs-fixer    ${CYAN} Apply Symfony Coding standard.${NC}"
	@echo "${YELLOW}Database Targets${NC}"
	@echo "  snapshot        ${CYAN} Make a bzipped database snapshot.${NC}"
	@echo "  import          ${CYAN} Import dump from a path.${NC}"
	@echo "  query           ${CYAN} Execute SQL statement.${NC}"

init:
	@if [ -d "srv" ]; then\
		echo "${RED}It seems that you already initialized the project, you may want to run ${NC}make clean${RED} to start over?";\
		exit 1;\
    fi
	@echo "${BLUE}Initialize ${NC}.env${BLUE}, ${NC}auth.json${BLUE} files...${NC}"
	@$(shell cp -f $(shell pwd)/.env.dist $(shell pwd)/.env 2> /dev/null)
	@$(shell cp -n $(shell pwd)/auth.json.dist $(shell pwd)/auth.json 2> /dev/null)
	@if [ $(app_name) != "" ]; then\
        echo "${BLUE}Adding '$(app_name)' to hosts...${NC}";\
        sudo sh ./docker/hosts.sh add "127.0.0.1 $(app_name).local admin.$(app_name).local";\
        sed -i -e "s/APP_NAME=sf/APP_NAME=$(app_name)/g; s/NGINX_HOST=sf.local/NGINX_HOST=$(app_name).local/g; s/MYSQL_DATABASE=db_sf/MYSQL_DATABASE=db_$(app_name)/g" .env;\
        rm -f .env-e;\
	fi
	@if [ $(repository) != "" -a $(branch) != "" ]; then\
		git clone -b $(branch) $(repository) srv;\
	else\
		composer create-project symfony/website-skeleton srv;\
	fi
	@echo "${GREEN}Done, ${NC}${RED}Please adapt ${NC}auth.json${RED} file with your Gitlab credentials.${NC}"

clean:
	@echo "${BLUE}Resetting ${NC}.env${BLUE}, ${NC}auth.json${BLUE} files...${NC}"
	@rm -f .env
	@rm -rf .data
	@rm -f auth.json
	@echo "${BLUE}Removing ${NC}srv/${BLUE} directory...${NC}"
	@rm -rf srv

start: check-db
	@if [ ! -f "srv/composer.json" ]; then\
        echo "${RED}Directory ${NC}srv/${RED} seems to be empty, did you forget to create/clone your ${ORANGE}Content${RED}pepper project?";\
        exit 1;\
    fi
	@if grep -q your.username "auth.json"; then\
		echo "${RED}Looks like you forgot to set your Gitlab credentials in ${NC}auth.json${RED} file?";\
		exit 2;\
	fi
	@if [ $(db) != "mysql" -a $(db) != "mariadb" ]; then\
		echo "${RED}Unrecognized db '$(db)'.${NC}";\
		exit 3;\
	fi
	@sed -i -e "s/DB_ENGINE=(.*)/DB_ENGINE=$(db)/g" .env && rm -f .env-e
	@$(shell cp -f $(shell pwd)/.env $(shell pwd)/srv/.env 2> /dev/null)
	@$(shell cp -f $(shell pwd)/auth.json $(shell pwd)/srv/auth.json 2> /dev/null)
	@echo "${BLUE}Starting containers with '$(db)'...${NC}"
	@if [ $(xdebug) = true ]; then\
    	echo "${BLUE}With 'xdebug', setting alias to 10.254.254.254...${NC}";\
    	sed -i -e "s/XDEBUG=(.*)/XDEBUG=$(xdebug)/g" .env && rm -f .env-e;\
    	if [ $(os) = "Darwin" ]; then\
    	    sudo ifconfig lo0 alias 10.254.254.254;\
    	else\
    	    sudo ifconfig lo:0 10.254.254.254 up;\
    	fi;\
	fi
	@if [ $(kibana) = true ]; then\
		echo "${BLUE}With 'kibana/logstash'...${NC}";\
		docker-compose -f docker-compose.yaml -f docker-compose.$(db).yaml -f docker-compose.kibana.yaml up -d --build;\
	else\
		docker-compose -f docker-compose.yaml -f docker-compose.$(db).yaml up -d --build;\
	fi
	@if [ $(os) = "Linux" ]; then\
		sudo chown -R "$(logname)":"$(logname)" .data;\
	fi

checkout:
	@echo "${BLUE}Checkouting $(branch) branch...${NC}"
	@cd srv && \
	    git checkout $(branch) && \
	    git pull origin $(branch) && \
	    docker-compose exec -T app composer config --global process-timeout 3600 && \
	    docker-compose exec -T app composer install

switch:
	@if [ ! -d "$(directory)" ]; then\
		echo "${RED}Couldn't resolve project directory ${NC}'$(directory)'${RED}, do you mean one of the following?${GREEN}";\
		for dir in $(ls_parent); do echo $(ppwd)/$${dir%/*}; done;\
		echo "${NC}";\
		exit 1;\
	fi
	@if [ -d "srv" ]; then\
		unlink srv;\
	fi
	@ln -s $(directory) srv
	@echo "${BLUE}Pointing to ${NC}$(shell basename $(directory))${BLUE} project...${NC}"
	@if [ $(os) = "Darwin" ]; then\
		timeout 2;\
		open -a PhpStorm $(directory);\
	fi

update:
	@echo "${BLUE}Updating...${NC}"
	@cd srv && \
	    git pull && \
	    docker-compose exec -T app composer config --global process-timeout 3600 && \
	    docker-compose exec -T app composer update

stop:
	@echo "${BLUE}Stopping all containers...${NC}"
	@docker-compose stop

restart:
	@make -s stop && make -s start db=$(DB_ENGINE)

logs:
	@docker-compose logs -f

snapshot:
	@docker exec -i $(APP_NAME)_$(DB_ENGINE) mysqldump --skip-extended-insert -uroot -proot $(MYSQL_DATABASE) > dump_$(APP_NAME)_$(time).sql | bzip2

import:
	@if [ ! -f "$(dump)" ]; then\
		echo "${RED}Missing path to the database dump!${NC}";\
		exit 1;\
	fi
	@docker exec -i $(APP_NAME)_$(DB_ENGINE) mysql --max_allowed_packet=100M -uroot -proot $(MYSQL_DATABASE) < $(dump)
	@echo "${GREEN}Import has been successfully finished, now re-populating Elasticsearch index...${NC}"

query:
	@if [ "$(sql)" = "" ]; then\
		echo "${RED}Missing query!${NC}";\
		exit 1;\
	fi
	@if [ "$(doctrine)" != "" ]; then\
		docker-compose exec -T app bin/console doctrine:query:sql '$(sql)' --no-debug;\
	else\
		docker exec -i $(APP_NAME)_$(DB_ENGINE) mysql -uroot -proot $(MYSQL_DATABASE) -e "$(sql)";\
	fi

console:
	@docker exec -ti $(APP_NAME)_app bash

housekeep:
	@docker image prune -a
	@docker system prune -a --volumes

encore:
	@docker-compose exec -T app yarn encore dev

cc:
	@docker-compose exec -T app bin/console doctrine:cache:clear-query --no-debug
	@docker-compose exec -T app bin/console doctrine:cache:clear-result --no-debug
	@docker-compose exec -T app bin/console doctrine:cache:clear-metadata --no-debug
	@docker-compose exec -T app bin/console cache:clear --no-debug

php-cs-fixer:
	@echo "${RED}FriendsOfPHP/PHP-CS-Fixer is not yet installed.${NC}"

check-db:
ifndef db
	$(error Missing required argument db! please specify a db-engine to use on current project)
endif

# Shell colors.
RED=\033[0;31m
LIGHT_RED=\033[1;31m
GREEN=\033[0;32m
LIGHT_GREEN=\033[1;32m
ORANGE=\033[0;33m
YELLOW=\033[1;33m
BLUE=\033[0;34m
LIGHT_BLUE=\033[1;34m
PURPLE=\033[0;35m
LIGHT_PURPLE=\033[1;35m
CYAN=\033[0;36m
LIGHT_CYAN=\033[1;36m
NC=\033[0m

.PHONY: start clean

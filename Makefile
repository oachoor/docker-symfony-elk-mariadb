db := mysql
xdebug := false
kibana := false
hostname := sandbox

help:
	@echo "${YELLOW}Commands:${NC}"
	@echo "  ${BOLD_BLUE}clean       ${NC}Clean files and directories.${NC}"
	@echo "  ${BOLD_BLUE}encore      ${NC}Build assets using Webpack.${NC}"
	@echo "  ${BOLD_BLUE}start       ${NC}Create and start containers.${NC}"
	@echo "  ${BOLD_BLUE}stop        ${NC}Stop and clear all services.${NC}"
	@echo "  ${BOLD_BLUE}logs        ${NC}Follow containers output logs.${NC}"

init:
	@$(shell cp -rf $(shell pwd)/docker-compose.dist.yaml $(shell pwd)/docker-compose.yaml 2> /dev/null)
	@if [ $(hostname) != "" ]; then\
        echo "${BLUE}Adding '$(hostname)' to hosts...${NC}";\
        sudo sh ./hosts.sh add "127.0.0.1 $(hostname).local";\
        sed -i -e "; s/nginx_host=sf.local/nginx_host=$(hostname).local/g" docker-compose.yaml;\
        rm -f docker-compose.yaml-e;\
	fi

clean:
	@if [ "$(force)" = "true" ]; then\
		echo "${BLUE}Reset files and directories...${NC}";\
		find .. -type f -maxdepth 1 -delete -print;\
		find .. -mindepth 1 -maxdepth 1 -type d -not \( -name "docker" \) -print -exec rm -rf {} +;\
	else\
		echo "${BOLD_RED}This do not usually happens but okay, the following files and directories will be removed:${NC}";\
		find .. -type f -maxdepth 1 -print;\
		find .. -mindepth 1 -maxdepth 1 -type d -not \( -name "docker" \) -print;\
		echo "${YELLOW}If so, then you may safely re-run the command with force:${NC} make clean force=true";\
	fi

start:
	@if [ ! -f "composer.json" ]; then\
        echo "${RED}Missing project files, forgot to init/clone your symfony project?";\
        exit 1;\
    fi
	@if [ ! -f docker-compose.yaml ]; then\
		echo "${RED}Missing docker-compose file, forgot to run 'make init'?";\
		exit 1;\
	fi
	@if [ $(db) != "mysql" -a $(db) != "mariadb" ]; then\
    	echo "${RED}Unrecognized db '$(db)'.${NC}";\
    	exit 2;\
	fi
	@echo "${BLUE}Starting containers with '$(db)'...${NC}"
	@if [ $(xdebug) = "true" ]; then\
    	echo "${BLUE}With 'xdebug', setting alias to 10.254.254.254...${NC}";\
    	sed -i -e "s/xdebug=false/xdebug=$(xdebug)/g" docker-compose.yaml && rm -f docker-compose.yaml-e;\
    	sudo ifconfig lo0 alias 10.254.254.254;\
	fi
	@if [ $(kibana) = "true" ]; then\
		echo "${BLUE}With 'kibana/logstash'...${NC}";\
		docker-compose -f docker-compose.yaml -f docker-compose.$(db).yaml -f docker-compose.kibana.yaml up --build;\
	else\
		docker-compose -f docker-compose.yaml -f docker-compose.$(db).yaml up --build --force-recreate;\
	fi

stop:
	@echo "${BLUE}Stopping all containers:${NC}"
	@docker-compose down -v

logs:
	@docker-compose logs -f

# Shell colors.
RED=\033[0;31m
BOLD_RED=\033[1;31m
GREEN=\033[0;32m
BOLD_GREEN=\033[1;32m
ORANGE=\033[0;33m
YELLOW=\033[1;33m
BLUE=\033[0;34m
BOLD_BLUE=\033[1;34m
PURPLE=\033[0;35m
BOLD_PURPLE=\033[1;35m
CYAN=\033[0;36m
BOLD_CYAN=\033[1;36m
NC=\033[0m

.PHONY: clean init
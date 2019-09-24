# Minimal Docker Stack for PHP projects

## Services

* [Nginx](https://nginx.org/)
* [PHP-FPM](https://php-fpm.org/)
* [MySQL](https://www.mysql.com/) | [MariaDB](https://mariadb.org/)
* [Elasticsearch](https://www.elastic.co/products/elasticsearch)
* [Logstash](https://www.elastic.co/products/logstash)
* [Kibana](https://www.elastic.co/products/kibana)
* [Redis](https://redis.io/)
* [Blackfire](https://blackfire.io/)
* [Kubernetes](https://kubernetes.io/)

## Requirements

This stack needs [docker](https://www.docker.com/community-edition#/download) and [docker-compose](https://docs.docker.com/compose/install) to be installed.

## Steps
    
1. `git clone https://github.com/oachoor/docker-lemp-stack.git my-project && cd my-project`
    
2. Initialize
    
    **Arguments:** 
     - *app_name* ("sf" by default), will be used as database name with 'db_' as prefix.
     - *repository* ("symfony/website-skeleton" by default), otherwise your Gitlab/Github url.
     - *branch* ("master" by default), will be used for cloning symfony.
    ```sh
    $ make init
    ```

3. (Optional - **MariaDB** only!) Setting "server_version" value:
    ```yaml
    # srv/config/packages/doctrine.yaml
    doctrine:
        dbal:
            server_version: 'mariadb-10.3.14'
    ```

5. Build & run containers

    **Important**: You may want to use MariaDB, Blackfire, Kibana or Xdebug? then keep/eliminate the arguments accordingly.
    ```bash
    $ make start db=mariadb
    ```
    
6. (Optional) Xdebug: Configure PHPStorm
    
    ![PHPStorm > Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy](docker/app/xdebug.png)
    
7. Done! you may run `make logs` to see the progress.

## How does it work?

We have the following *docker-compose* built images:

* `nginx`: The Nginx webserver container in which the application volume is mounted.
* `app`: The PHP-FPM container in which the application volume is mounted too.
* `mysql`: The MySQL database container.
* `elasticsearch`: The Elasticsearch container.
* `redis`: The Redis server container.

Running `docker-compose ps` should result in the following running containers:

```
Name                Command                          State   Ports
-----------------------------------------------------------------------------------------------------
sf_app              docker-php-entrypoi              Up      9000/tcp
sf_nginx            nginx                            Up      0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
sf_mysql            /entrypoint.sh mysqld            Up      0.0.0.0:3306->3306/tcp
sf_redis            docker-entrypoint.sh             Up      6379/tcp
sf_elasticsearch    /usr/bin/supervisord -n -c ...   Up      0.0.0.0:9200->9200/tcp, 9300/tcp
```

## Usage

Once all the containers are up, our services are available at (http/https):

* Application: `http://sf.local:80`
* Mysql server: `http://sf.local:3307`
* Redis: `http://sf.local:11211`
* Elasticsearch: `http://sf.local:9200`
* Kibana: `http://sf.local:5601`
* Log files location: *var/logs/nginx* and *var/logs/symfony*

## Task lists

- [ ] Automate Source-drivers and daemons cronjobs.
- [x] Automate cloning repository + executing symfony commands.
- [ ] Automate Download and Import SQL dump from Amazon S3 + Storage.
- [x] Work on ENV file to setup (hostname, es-indexes, parameters etc...) per project.
- [x] Review and Optimize Docker-sync.
- [ ] Know How To Share Data between Docker Containers. (**Kubernetes**).
- [ ] Start multiple services exposing the same port (e.g 80).
- [x] Using common containers (eg, mysql, elk) for all installations.
- [x] Adjust automated deployment to work with docker instead of vagrant.
- [ ] Adjust automated test-execution to run with the docker stack.
- [ ] Activate and Switching between builds (**Ansible**).
- [x] Dynamic .env file - support multiple projects per repository (demo-marc, demo-sales).
- [x] Policies per project. (Deprecated since 2.0)
- [x] Apache / Nginx / Varnish templates.
- [ ] Setup hosts file between containers.
- [ ] Implement Logrotate.

:tada: Now we can stop our stack with `make stop` and start it again with `make start`

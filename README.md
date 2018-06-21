# Docker stack for Symfony3 projects

## Basic info

* [Nginx](https://nginx.org/)
* [PHP-FPM](https://php-fpm.org/)
* [MySQL](https://www.mysql.com/)
* [Memcached](https://memcached.org/)
* [Elasticsearch](https://www.elastic.co/products/elasticsearch)
* [Logstash](https://www.elastic.co/products/logstash)
* [Kibana](https://www.elastic.co/products/kibana)
* [RabbitMQ](https://www.rabbitmq.com/)
* [OPcache](http://php.net/manual/en/book.opcache.php)
* [XDebug](https://xdebug.org/)
* NodeJS & NPM
* UglifyJS & UglifyCSS
* Logrotate
* Crontab

## Requirements

This stack needs [docker](https://www.docker.com/) and [docker-compose](https://docs.docker.com/compose/) to be installed, as for [docker-sync](https://github.com/EugenMayer/docker-sync/wiki/1.-Installation) only if needed.

## Installation

1. Clone or download this repo and merge it with your project.

2. Rename `.env.dist` file to `.env` and adapt it according to the needs of the application (e.g project hostname)

    ```sh
    $ cp .env.dist .env && nano .env
    ```

3.  Due to an Elasticsearch 6 requirement, we need to set a host's sysctl option and restart Docker ([More info](https://github.com/spujadas/elk-docker/issues/92)):

    If it asks you for a username and password, Log in with root and no password.
    If it just has a blank screen, press Return.
    Then configure the sysctl setting as you would for Linux:

    ```sh
    $ screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty
    $ sysctl -w vm.max_map_count=262144
    ```
    
    Exit by Control-A Control-\.
    
    In some cases, this change does not persist across restarts of the VM. So, while screen'd into, edit the file /etc/sysctl.d/00-alpine.conf and add the parameter vm.max_map_count=262144 to the end of file. 
  
4. Build and run the stack in detached mode (stop any system's ngixn/apache2, mysql, elasticsearch services first)

    OSX :
    ```sh
    $ sudo nginx -s stop 
    $ sudo apachectl -k stop
    $ sudo brew services stop mysql or sudo launchctl unload -w /Library/LaunchDaemons/com.mysql.mysql.plist
    
    ```
    
    Linux :
    ```sh
    $ sudo service nginx stop or sudo /etc/init.d/nginx stop
    $ sudo service apache2 stop or sudo /etc/init.d/apache2 stop
    $ sudo service mysqld stop or sudo /etc/init.d/mysql stop
    ```
    
    Windows :
    ```sh
    $ By turning-off EasyPHP, WAMP or other tool, but feel free to contribute!
    ```
    
    Ready ?
    ```sh
    $ docker-compose up --build
    ```
    
    Using Docker-Sync ?
    ```sh
    $ docker-sync start
    $ docker-sync-stack start
    ```
    
5. Get bridge's IP address

    ```sh
    $ docker network inspect bridge | grep Gateway | grep -o -E '[0-9\.]+'
    ```

6. Update your system's hosts file with the IP retrieved in **step 5** or with 127.0.0.1

8. Prepare the Symfony application
    1. Update Symfony env variables (*.env*)

        ```
        #...
        DATABASE_URL=mysql://db_user:db_password@mysql:3307/db_name
        #...
        ```
   
    2. Composer install & run the commands from the container
        ```sh 
        $ docker exec -e COLUMNS="`tput cols`" -e LINES="`tput lines`" -ti sandbox_php bash
        $ php -dmemory_limit=-1 /usr/local/bin/composer install
        $ bin/console assets:install --symlink --relative --env=dev
        $ bin/console assetic:dump --env=dev
        $ bin/console cache:clear --env=dev
        $ bin/console doctrine:schema:update --force
	    ```

9. (Optional) Xdebug: Configure your IDE to connect to port `9001` with key `PHPSTORM`
    
    Because of its nature, docker-for-mac won’t allow you to simply put xdebug.remote_connect_back=1 in your xdebug.ini file – due to the nature of connection_back, it just won’t work. There are a few workarounds, but the one I use creates 10.254.254.254 as an alias on your loopback device (127.0.0.1). This one command in Terminal will do it:
    ```
    $ sudo ifconfig lo0 alias 10.254.254.254
    ```
    ![PHPStorm > Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy](doc/docker/img/xdebug.png)

## How does it work?

We have the following *docker-compose* built images:

* `nginx`: The Nginx webserver container in which the application volume is mounted.
* `php`: The PHP-FPM container in which the application volume is mounted too.
* `mysql`: The MySQL database container.
* `elk`: Container which uses Logstash to collect logs, send them into Elasticsearch and visualize them with Kibana.
* `memcached`: The Memcached server container.
* `redis`: The Redis server container.
* `rabbitmq`: The RabbitMQ server/administration container.

Running `docker-compose ps` should result in the following running containers:

```
Name                  Command                          State   Ports
------------------------------------------------------------------------------------------------------------------------
sandbox_mysql         /entrypoint.sh mysqld            Up      0.0.0.0:3306->3306/tcp
sandbox_nginx         nginx                            Up      443/tcp, 0.0.0.0:80->80/tcp
sandbox_phpfpm        php-fpm                          Up      0.0.0.0:9000->9000/tcp
sandbox_memcached     docker-entrypoint.sh memcac...   Up      11211/tcp
sandbox_redis         docker-entrypoint.sh redis...    Up      6379/tcp
sandbox_rabbit        rabbitmq:3-management            Up      4369/tcp, 5671/tcp, 0.0.0.0:5672->5672/tcp, 15671/tcp, 25672/tcp, 0.0.0.0:15672->15672
sandbox_elk           /usr/bin/supervisord -n -c ...   Up      0.0.0.0:5044->5044/tcp, 0.0.0.0:5601->5601/tcp, 0.0.0.0:9200->9200/tcp, 9300/tcp
```

## Usage

Once all up and running, our containers are available at :

* Symfony app: `http://sandbox.tld:80`
* Mysql server: `http://sandbox.tld:3307`
* Memcached: `http://sandbox.tld:11211`
* Redis: `http://sandbox.tld:6379`
* Elasticsearch: `http://sandbox.tld:9200`
* Kibana: `http://sandbox.tld:5601`
* RabbitMQ: `http://sandbox.tld:15672`
* Log files location: *var/logs/nginx* and *var/logs/sandbox*

## Commands

##### React Dev
Watch file changes
```sh
$ cd to/your/ui/directory
$ npm install && npm run watch
```
Open another terminal tab and run assetic:watch in parallel
```sh
$ bin/console assetic:watch
```

##### Flush Memcached
```sh
docker exec -e COLUMNS="`tput cols`" -e LINES="`tput lines`" -ti sandbox_memcached bash
memcache@c24e5d906f70:/$ echo flush_all > /dev/tcp/127.0.0.1/11211
```

##### Import your database
        
```sh
$ bunzip2 < your/mysql/snapshot.sql.bz2 | docker exec -i sandbox_mysql /usr/bin/mysql -u root -proot db_name
```

In progress...

## Tasks

- [ ] Automate Download and Import SQL dump from Amazon S3.
- [ ] Automate Download and Import SQL dump from Amazon S3.
- [ ] Start multiple services exposing the same port (e.g 80).
- [ ] Using common containers (eg, mysql, elk) for all installations.
- [ ] Activate and Switching between builds (**Ansible?**).
- [ ] Apache / Nginx / Varnish templates.

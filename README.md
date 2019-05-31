# Minimal Docker Stack for Symfony4 projects

## Services

* [Nginx](https://nginx.org/)
* [PHP-FPM](https://php-fpm.org/)
* [MySQL](https://www.mysql.com/) | [MariaDB](https://mariadb.org/)
* [Elasticsearch](https://www.elastic.co/products/elasticsearch)
* [Logstash](https://www.elastic.co/products/logstash)
* [Kibana](https://www.elastic.co/products/kibana)
* [Redis](https://redis.io/)

##  Requirements

1. This stack needs [docker](https://www.docker.com/community-edition#/download) and [docker-compose](https://docs.docker.com/compose/install) to be installed.

2. Run Docker and adjust the settings minimum as following:

     **Advanced >**
	 - **CPUs** : 4
	 - **Memory** : 4.0 GiB
	 - **Swap** : 1.0 GiB
	
	**File Sharing >**
			Make sure the folder (shared path) of your installation is listed, otherwise simply add it.
    
3. Stop any system's ngixn/apache2, mysql, elasticsearch, redis services
   
   OSX:
   ```sh
   $ sudo nginx -s stop 
   $ sudo apachectl -k stop
   $ redis-cli shutdown
   $ sudo brew services stop mysql or sudo launchctl unload -w /Library/LaunchDaemons/com.mysql.mysql.plist
   
   ```
   
   Linux:
   ```sh
   $ sudo service nginx stop or sudo /etc/init.d/nginx stop
   $ sudo service apache2 stop or sudo /etc/init.d/apache2 stop
   $ sudo service mysqld stop or sudo /etc/init.d/mysql stop
   $ sudo /etc/init.d/redis-server stop
   ```
   
   Windows: (Only tested on Linux and OSX, perhaps it could work on Windows)
   ```sh
   $ By turning-off EasyPHP, WAMP or any other tool...
   ```
4.  Due to an Elasticsearch 6 requirement, we may need to set a host's sysctl option and restart ([More info](https://github.com/spujadas/elk-docker/issues/92)):

    If it asks you for a username and password, Log in with root and no password.
    If it just has a blank screen, press Return.
    Then configure the sysctl setting as you would for Linux:

    ```sh
    $ screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty
    $ sysctl -w vm.max_map_count=262144
    ```
    
    Exit by Control-A Control-\.
    
    In some cases, this change does not persist across restarts of the VM. So, while screen'd into, edit the file /etc/sysctl.d/00-alpine.conf and add the parameter vm.max_map_count=262144 to the end of file.

## Steps

1. Initialize, clone or download your symfony repository and cd to it.

2. Clone this repository inside
    ```sh
    $ git clone https://github.com/oachoor/docker-for-symfony.git docker && rm -rf docker/.git
    ```

3. Initialize docker-compose file
    
    **Note** *app_name* ("sandbox" by default) will be used as hostname.
    ```sh
    $ cd docker
    $ make init app_name=mybox
    ```

4. Build & run containers

    **Important**: You may want to use MariaDB, Kibana or Xdebug? then keep/eliminate the arguments accordingly.
    ```bash
    $ make start db=mariadb xdebug=true kibana=true
    ```
    
5. (Optional) Xdebug: Configure PHPStorm
    
    ![PHPStorm > Preferences > Languages & Frameworks > PHP > Debug > DBGp Proxy](app/xdebug.png)

## How does it work?

We have the following *docker-compose* built images:

* `nginx`: The Nginx webserver container in which the application volume is mounted.
* `app`: The PHP-FPM container in which the application volume is mounted too.
* `mysql`: The MySQL database container.
* `elasticsearch`: The Elasticsearch container.
* `redis`: The Redis server container.

Running `docker-compose ps` should result in the following running containers:

```
Name                     Command                          State   Ports
-----------------------------------------------------------------------------------------------------
sandbox_app              docker-php-entrypoi              Up      9000/tcp
sandbox_nginx            nginx                            Up      0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
sandbox_mysql            /entrypoint.sh mysqld            Up      0.0.0.0:3306->3306/tcp
sandbox_redis            docker-entrypoint.sh             Up      6379/tcp
sandbox_elasticsearch    /usr/bin/supervisord -n -c ...   Up      0.0.0.0:9200->9200/tcp, 9300/tcp
```

## Usage

Once all the containers are up, our services are available at:

* Sandbox: `http(s)://sandbox.local:80`
* Mysql server: `http(s)://sandbox.local:3307`
* Redis: `http(s)://redis.local:11211`
* Elasticsearch: `http(s)://sandbox.local:9200`
* Kibana: `http(s)://sandbox.local:5601`

## Task lists

- [ ] Implement Varnish container.
- [ ] Implement Logrotate.
- [ ] Automate Download and Import SQL dump from Amazon S3.
- [ ] Optimize Xdebug.

:tada: Now we can stop our stack with `make down` and start it again with `make start`

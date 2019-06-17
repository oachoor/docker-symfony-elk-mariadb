FROM php:7.3.5-fpm

ARG timezone
ARG xdebug=false

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    g++ \
    libbz2-dev \
    libc-client-dev \
    libcurl4-gnutls-dev \
    libedit-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libkrb5-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libpq-dev \
    libsqlite3-dev \
    libssl-dev \
    libreadline-dev \
    libxslt1-dev \
    libzip-dev \
    wget \
    git \
    vim \
    unzip \
    zlib1g-dev \
    && docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) imap \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    bz2 \
    calendar \
    exif \
    gettext \
    mysqli \
    opcache \
    pdo_mysql \
    soap \
    sockets \
    xmlrpc \
    xsl \
    && docker-php-ext-configure zip --with-libzip \
    && docker-php-ext-install zip \
    && pecl install redis && docker-php-ext-enable redis \
    && yes '' | pecl install imagick && docker-php-ext-enable imagick \
    && docker-php-source delete \
    && apt-get remove -y g++ wget \
    && apt-get autoremove --purge -y && apt-get autoclean -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Xdebug
COPY xdebug.ini /tmp/xdebug.ini
RUN if [ $xdebug = "true" ] ; then \
        pecl install xdebug; \
        docker-php-ext-enable xdebug; \
        cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    fi ;
RUN rm /tmp/xdebug.ini

# NodeJS/NPM?
RUN apt-get update &&\
    apt-get install -y --no-install-recommends gnupg &&\
    curl -sL https://deb.nodesource.com/setup_10.x | bash - &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends nodejs &&\
    npm install -g npm@latest &&\
    npm install -g less &&\
    npm install -g less-loader

# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends yarn &&\
    yarn global add less &&\
    yarn global add less-loader

# PHP-CS-Fixer
#RUN wget http://cs.sensiolabs.org/download/php-cs-fixer-v2.phar -O php-cs-fixer \
#    && chmod a+x php-cs-fixer \
#    && mv php-cs-fixer /usr/local/bin/php-cs-fixer

COPY php.ini /usr/local/etc/php/php.ini
# Tweak php-fpm config
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 70/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 20/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 20/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 35/g" /usr/local/etc/php-fpm.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 500/g" /usr/local/etc/php-fpm.d/www.conf
    #sed -i -e "s/user = www-data/user = web/g" /usr/local/etc/php-fpm.d/www.conf && \
    #sed -i -e "s/group = www-data/group = staff/g" /usr/local/etc/php-fpm.d/www.conf

RUN sed -i -e "s#TIMEZONE#$timezone#g" /usr/local/etc/php/php.ini

COPY --from=composer:1.8 /usr/bin/composer /usr/bin/composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1
# create composer cache directory
RUN mkdir -p /var/www/.composer && chown -R www-data /var/www/.composer

# Setup and install base system software
RUN echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections \
    && echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections \
    && apt-get update \
    && apt-get --yes --no-install-recommends install \
        locales tzdata ca-certificates sudo \
        bash-completion iproute2 curl nano tree \
    && rm -rf /var/lib/apt/lists/*
ENV LANG en_US.UTF-8

RUN echo 'alias sf="bin/console"' >> ~/.bashrc \
&& echo 'alias cc="bin/console cache:clear"' >> ~/.bashrc \
&& echo 'alias ll="ls -la"' >> ~/.bashrc

WORKDIR /srv

COPY entrypoint.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/entrypoint.sh \
    && ln -s /usr/local/bin/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]

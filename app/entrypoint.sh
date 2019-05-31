#!/usr/bin/env bash
set -e

if [[ ! -f 'composer.lock' ]]; then
    echo "Composer install..."
    git config --global http.sslverify false
    composer config --global process-timeout 3000
    composer config --global github-protocols https
    composer clear-cache
    php -d memory_limit=-1 $(which composer) install --no-progress --no-interaction

    #echo "Schema update..."
    #bin/console d:s:u --force --no-debug
fi

exec "$@"

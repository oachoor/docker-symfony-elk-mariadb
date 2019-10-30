#!/usr/bin/env bash
set -e

if [[ ! -d "vendor" ]]; then
    echo "Composer install..."
    git config --global http.sslverify false
    composer config --global process-timeout 3600
    composer config --global github-protocols https
    composer clear-cache

    # Wait until all packages are installed.
    while [[ $(composer install --dry-run 2>&1 | grep -qi "Nothing to install or update" && echo "i") != "i" ]]; do
        php -d memory_limit=-1 $(which composer) install --no-progress --no-interaction
    done
fi


exec "$@"

#!/bin/bash

echo "Composer"
composer config --global process-timeout 3000
composer install --optimize-autoloader --no-progress --no-interaction --prefer-dist

echo "ElasticSearch Reset/Populate Index\n";
#bin/console fos:elastica:populate --index=sandbox_index

echo "Assets/Cache"
bin/console assets:install --symlink --env=dev
bin/console assetic:dump --env=dev
bin/console cache:clear --env=dev

echo "Doctrine"
bin/console doctrine:schema:update --force

echo "Chmod"
chmod 777 -R var/
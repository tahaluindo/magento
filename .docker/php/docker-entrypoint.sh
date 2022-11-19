#!/bin/bash

[ "$DEBUG" = "true" ] && set -x

PHP_EXT_DIR=/usr/local/etc/php/conf.d

# Enable PHP extensions
PHP_EXT_COM_ON=docker-php-ext-enable

[ -d ${PHP_EXT_DIR} ] && rm -f ${PHP_EXT_DIR}/docker-php-ext-*.ini

if [ -x "$(command -v ${PHP_EXT_COM_ON})" ] && [ ! -z "${PHP_EXTENSIONS}" ]; then
  ${PHP_EXT_COM_ON} ${PHP_EXTENSIONS}
fi

# Set host.docker.internal if not available
HOST_NAME="host.docker.internal"
HOST_IP=$(php -r "putenv('RES_OPTIONS=retrans:1 retry:1 timeout:1 attempts:1'); echo gethostbyname('$HOST_NAME');")
if [[ "$HOST_IP" == "$HOST_NAME" ]]; then
  HOST_IP=$(/sbin/ip route|awk '/default/ { print $3 }')
  printf "\n%s %s\n" "$HOST_IP" "$HOST_NAME" >> /etc/hosts
fi

composer install --prefer-dist --no-progress --no-suggest --no-interaction

INSTALL=$(bin/magento config:show 2>&1 >/dev/null | grep "There are no commands defined")

if [ ! -z "$INSTALL" ]; then
  bin/magento setup:install \
  --db-host=$DB_HOST \
  --db-name=$DB_NAME \
  --db-user=$DB_USER \
  --db-password=$DB_PASSWORD \
  --admin-firstname=$ADMIN_FIRST_NAME \
  --admin-lastname=$ADMIN_LAST_NAME \
  --admin-email=$ADMIN_EMAIL \
  --admin-user=$ADMIN_USER \
  --admin-password=$ADMIN_PASSWORD \
  --use-rewrites=$USE_REWRITES \
  --elasticsearch-host=$ELASTIC_SEARCH_HOST \
  --elasticsearch-port=$ELASTIC_SEARCH_PORT \
  --session-save=$SESSION_SAVE \
  --use-secure=$USE_SECURE \
  --use-secure-admin=$USE_SECURE_ADMIN \
  --backend-frontname=$BACKEND_FRONTNAME \
  --base-url=$BASE_URL \
  --base-url-secure=$BASE_URL_SECURE
fi

bin/magento deploy:mode:set production

#check if 2fa needs to be enabled or disabled
if [ $TWO_FACTOR_AUTH -eq 1 ]; then
  bin/magento module:enable "Magento_TwoFactorAuth"
else
  bin/magento module:disable "Magento_TwoFactorAuth"
fi

exec "$@"
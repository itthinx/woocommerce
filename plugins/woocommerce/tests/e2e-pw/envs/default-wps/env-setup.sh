#!/bin/bash

set -eo pipefail

echo "Default environment (+ WooCommerce Product Search plugin) setup."

SCRIPT_PATH=$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || return
  pwd -P
)



#DOCKER_CONTAINER_ID=$(docker ps --filter "label=com.docker.compose.service=wordpress" --format "{{.ID}}")

#echo "DOCKER_CONTAINER_ID = ${DOCKER_CONTAINER_ID}"

# docker cp ../../../woocommerce-product-search.zip "$DOCKER_CONTAINER_ID:/tmp/woocommerce-product-search.zip"
# docker cp ../../../woocommerce-product-search.zip "$DOCKER_CONTAINER_ID:/var/www/html/woocommerce-product-search.zip"

# docker cp ../../../woocommerce-product-search.zip "$DOCKER_CONTAINER_ID:/var/www/html/wp-content/plugins/woocommerce-product-search.zip"

# unzip ../../../woocommerce-product-search.zip

# docker cp ../../../woocommerce-product-search "$DOCKER_CONTAINER_ID:/var/www/html/wp-content/plugins/woocommerce-product-search"

#CURRENT_PATH=$(
#	pwd -P
#)

#echo "SCRIPT_PATH = ${SCRIPT_PATH}"
#echo "CURRENT_PATH = ${CURRENT_PATH}"

#echo "BASH_SOURCE = ${BASH_SOURCE}"

#ZIP_PATH="${CURRENT_PATH}/../../../woocommerce-product-search.zip"
#echo "ZIP_PATH = ${ZIP_PATH}"

#if [ -f $ZIP_PATH ]; then
#	echo "zip exists"
#fi

# pnpm wp-env run tests-cli wp plugin install $ZIP_PATH --activate

# pnpm wp-env run tests-cli wp plugin install /tmp/woocommerce-product-search.zip --activate
# pnpm wp-env run tests-cli wp plugin install http://localhost:8888/woocommerce-product-search.zip --activate
# pnpm wp-env run tests-cli wp plugin list
# pnpm wp-env run tests-cli wp plugin activate woocommerce-product-search


# pnpm wp-env run tests-cli wp plugin install /var/www/html/wp-content/plugins/woocommerce-product-search.zip --activate


DOCKER_CONTAINER_ID=$(docker ps --filter "label=com.docker.compose.service=tests-wordpress" --format "{{.ID}}")
echo "DOCKER_CONTAINER_ID = ${DOCKER_CONTAINER_ID}"

# docker cp ../../../woocommerce-product-search.zip "$DOCKER_CONTAINER_ID:/tmp/woocommerce-product-search.zip"
# pnpm wp-env run tests-cli wp plugin install /tmp/woocommerce-product-search.zip --activate

# @todo make sure the zip file exists, complain and ask to put it where it needs to be
# @todo if unzipped folder already exists, remove before unzipping

unzip ../../../woocommerce-product-search.zip

docker cp ../../../woocommerce-product-search "$DOCKER_CONTAINER_ID:/var/www/html/wp-content/plugins/woocommerce-product-search"

pnpm wp-env run tests-cli wp plugin list

pnpm wp-env run tests-cli wp plugin activate woocommerce-product-search




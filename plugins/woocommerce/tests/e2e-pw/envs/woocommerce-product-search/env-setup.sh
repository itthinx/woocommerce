#!/bin/bash

set -eo pipefail

echo "Default environment (+ WooCommerce Product Search plugin from zip) setup."

SCRIPT_PATH=$(
	cd "$(dirname "${BASH_SOURCE[0]}")" || return
	pwd -P
)

# Extract the zip and copy it to the Docker container
PLUGIN_ZIP="../../../woocommerce-product-search.zip"
if [ ! -f $PLUGIN_ZIP ]
then
	echo "Plugin zip $PLUGIN_ZIP must be present!" && exit 1
fi

TMPDIR=$(mktemp -d)
unzip $PLUGIN_ZIP -d $TMPDIR

DOCKER_CONTAINER_ID=$(docker ps --filter "label=com.docker.compose.service=tests-wordpress" --format "{{.ID}}")
if [ -z "$DOCKER_CONTAINER_ID" ]
then
	echo "Docker container not found! There is not container whose com.docker.compose.service label is tests-wordpress." && exit 1
fi
echo "DOCKER_CONTAINER_ID = ${DOCKER_CONTAINER_ID}"
docker cp "$TMPDIR/woocommerce-product-search" "$DOCKER_CONTAINER_ID:/var/www/html/wp-content/plugins/woocommerce-product-search"

rm -r $TMPDIR

pnpm wp-env run tests-cli wp plugin list

pnpm wp-env run tests-cli wp plugin activate woocommerce-product-search

PLUGIN_SLUG="woocommerce-product-search"
pnpm wp-env run tests-cli wp plugin is-active "$PLUGIN_SLUG" || ( echo "Plugin \"$PLUGIN_SLUG\" is not active!" && exit 1 )

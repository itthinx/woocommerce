#!/bin/bash
#
# Run:
#
# 1. Restart to environment so we start with a clean install:
# pnpm env:restart
#
# 2. Run the E2E tests:
# pnpm test:e2e:with-env volume-discount-coupons --project=e2e
#
# 3. Start fresh once more:
# pnpm env:restart
#
# 4. Run the API tests:
# pnpm test:e2e:with-env volume-discount-coupons --project=api

set -eo pipefail

echo "Default environment (+ Volume Discount Coupons plugin from zip) setup."

SCRIPT_PATH=$(
	cd "$(dirname "${BASH_SOURCE[0]}")" || return
	pwd -P
)

# Extract the zip and copy it to the Docker container
PLUGIN_ZIP="../../../volume-discount-coupons.zip"
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
docker cp "$TMPDIR/volume-discount-coupons" "$DOCKER_CONTAINER_ID:/var/www/html/wp-content/plugins/volume-discount-coupons"

echo "... copied to Docker Container"

# this fails :/
# echo "TMPDIR = $TMPDIR"
# rm -rf "$TMPDIR"
# echo "... removed temporary directory"

pnpm wp-env run tests-cli wp plugin list

echo "... after plugin list"

pnpm wp-env run tests-cli wp plugin activate volume-discount-coupons

echo "... after activate"

PLUGIN_SLUG="volume-discount-coupons"
pnpm wp-env run tests-cli wp plugin is-active "$PLUGIN_SLUG" || ( echo "Plugin \"$PLUGIN_SLUG\" is not active!" && exit 1 )



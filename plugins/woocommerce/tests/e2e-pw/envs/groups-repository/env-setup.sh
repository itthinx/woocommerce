#!/bin/bash

# Run from within plugins/woocommerce using the latest release
# $ pnpm test:e2e:with-env groups-repository
#
# Using a specific release:
# $ pnpm test:e2e:with-env groups-repository --release=3.7.0
#
# Using a specific branch:
# $ pnpm test:e2e:with-env groups-repository --branch=tested-3.8.0-3.8

set -eo pipefail

echo "Default environment (+ Groups plugin from release or branch) setup."

SCRIPT_PATH=$(
	cd "$(dirname "${BASH_SOURCE[0]}")" || return
	pwd -P
)

BRANCH=""
RELEASE="latest"

while [ $# -gt 0 ]; do
	case "$1" in
		# --branch value or --branch=value
		--branch|--branch=*)
			# no "=" take next value
			if [[ "$1" != *=* ]]; then shift; fi
			BRANCH="${1#*=}"
			if [[ -z "$BRANCH" ]]; then
				BRANCH="master"
			fi
			;;
		--release|--release=*)
			# no "=" take next value
			if [[ "$1" != *=* ]]; then shift; fi
			RELEASE="${1#*=}"
			;;
	esac
	shift
done

if [[ -z "$BRANCH" ]]; then
	echo "Installing Groups from release $RELEASE"
	if [[ $RELEASE = "latest" ]]
	then
		# Groups has no browser_download_url entry, modify when/if build process changes
		# download_url=$( curl -s "https://api.github.com/repos/itthinx/groups/releases/$RELEASE" | grep browser_download_url | cut -d '"' -f 4 )
		download_url=$( curl -s "https://api.github.com/repos/itthinx/groups/releases/$RELEASE" | grep zipball_url | cut -d '"' -f 4 )
	else
		download_url="https://api.github.com/repos/itthinx/groups/releases/tags/$RELEASE"
	fi
else
	echo "Installing Groups from branch $BRANCH"
	download_url="https://github.com/itthinx/groups/archive/refs/heads/$BRANCH.zip"
fi

echo "Downloading ... $download_url"
FILENAME=$(wget --content-disposition --server-response -q $download_url 2>&1 | awk -F"filename=" '{if ($2) print $2}')
temp_dir=$(mktemp -d)
unzip $FILENAME -d $temp_dir
DIRNAME=$(ls -1 "$temp_dir" | head -n 1)
mv "$temp_dir/$DIRNAME" "$temp_dir/groups"
# copy to docker
DOCKER_CONTAINER_ID=$(docker ps --filter "label=com.docker.compose.service=tests-wordpress" --format "{{.ID}}")
echo "DOCKER_CONTAINER_ID = ${DOCKER_CONTAINER_ID}"
docker cp "$temp_dir/groups" "$DOCKER_CONTAINER_ID:/var/www/html/wp-content/plugins/groups"
# clean up temp
rm -r $temp_dir

pnpm wp-env run tests-cli wp plugin list
pnpm wp-env run tests-cli wp plugin activate groups

PLUGIN_SLUG="groups"
pnpm wp-env run tests-cli wp plugin is-active "$PLUGIN_SLUG" || ( echo "Plugin \"$PLUGIN_SLUG\" is not active!" && exit 1 )

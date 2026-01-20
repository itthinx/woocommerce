#!/bin/bash
#
# Use the BRANCH or RELEASE environment variables to specify with which version from the repository to work.
#
# Currently we can not receive --branch or --release arguments,
# because the calling script run-tests-with-env.sh does not pass any arguments to this script.
# The following invocations are currently NOT SUPPORTED:
# $ pnpm test:e2e:with-env groups-repository --release=3.7.0
# $ pnpm test:e2e:with-env groups-repository --branch
# $ pnpm test:e2e:with-env groups-repository --branch=tested-3.8.0-6.8
# $ pnpm test:e2e:with-env groups-repository --branch=tested-3.8.0-6.8 --project=e2e
# See the EXAMPLES BELOW for examples using environment variables instead.
#
# If at a later point the script does pass other arguments, we need to make sure
# to consume the branch and/or release parameters so they are not present anymore
# when run-tests-with-env.sh invokes
# pnpm playwright test --config="$configFile" "$@"
# as the call will complain about unsupported parameters.
#
# Usage:
#
# Run this from within plugins/woocommerce ...
#
# Run all tests using the latest release
# $ pnpm test:e2e:with-env groups-repository
#
# Run all tests using a specific release:
# $ env RELEASE="3.7.0" pnpm test:e2e:with-env groups-repository
#
# Run all tests using the master branch:
# $ env BRANCH="master" pnpm test:e2e:with-env groups-repository
#
# Run all tests using a specific branch:
# $ env BRANCH="tested-3.8.0-6.8" pnpm test:e2e:with-env groups-repository
#
# Run only E2E tests using the latest release:
# $ pnpm test:e2e:with-env groups-repository --project=e2e
#
# Run only API tests, using the latest release:
# $ pnpm test:e2e:with-env groups-repository --project=api
#
# Run only E2E tests using a specific branch:
# $ env BRANCH="tested-3.8.0-6.8" pnpm test:e2e:with-env groups-repository --project=e2e
#

set -eo pipefail

echo "Default environment (+ Groups plugin from release or branch) setup."

SCRIPT_PATH=$(
	cd "$(dirname "${BASH_SOURCE[0]}")" || return
	pwd -P
)

if [ -z $BRANCH ]
then
	BRANCH=""
fi
if [ -z $RELEASE ]
then
	RELEASE="latest"
fi

#
# Code to obtain --branch or --release arguments which is not possible for the reasons outlined above.
#
#args=( )
#while [ $# -gt 0 ]; do
#	case "$1" in
#		# --branch value or --branch=value
#		--branch|--branch=*)
#			# no "=" take next value
#			if [[ "$1" != *=* ]]; then shift; fi
#			BRANCH="${1#*=}"
#			if [[ -z "$BRANCH" ]]; then
#				BRANCH="master"
#			fi
#			;;
#		--release|--release=*)
#			# no "=" take next value
#			if [[ "$1" != *=* ]]; then shift; fi
#			RELEASE="${1#*=}"
#			;;
#		*)
#			args+=( "$1" )
#			echo "ARGS: $args"
#			;;
#	esac
#	shift
#done
#
#set -- "${args[@]}"

if [[ -z "$BRANCH" ]]; then
	echo "Installing Groups from release $RELEASE"
	if [[ $RELEASE = "latest" ]]
	then
		# Groups has no browser_download_url entry, modify when/if build process changes
		# download_url=$( curl -s "https://api.github.com/repos/itthinx/groups/releases/$RELEASE" | grep browser_download_url | cut -d '"' -f 4 )
		download_url=$( curl -s "https://api.github.com/repos/itthinx/groups/releases/$RELEASE" | grep zipball_url | cut -d '"' -f 4 )
	else
		download_url="https://github.com/itthinx/groups/archive/refs/tags/$RELEASE.zip"
	fi
else
	echo "Installing Groups from branch $BRANCH"
	download_url="https://github.com/itthinx/groups/archive/refs/heads/$BRANCH.zip"
	echo "Download URL $download_url"
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

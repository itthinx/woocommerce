#!/bin/bash

set -eo pipefail

echo "Default environment (+ Groups plugin) setup."

pnpm wp-env run tests-cli wp plugin install groups --activate

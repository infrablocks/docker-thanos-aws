#!/usr/bin/env bash

[ -n "$DEBUG" ] && set -x
set -e
set -o pipefail

export TERM=xterm

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/../../.." && pwd )"

cd "$PROJECT_DIR"

git crypt unlock
git pull

./go version:release

./go images:base:publish
./go images:sidecar:publish
./go images:query:publish
./go images:store:publish
./go images:compact:publish

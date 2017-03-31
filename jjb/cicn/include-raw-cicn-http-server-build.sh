#!/bin/bash
# basic build script example
set -euo pipefail
IFS=$'\n\t'

source ./build-package.sh

PACKAGE_NAME="HTTP_SERVER"
PACKAGE_DEPS="HTTP_SERVER_DEPS"
build_package $PACKAGE_NAME $PACKAGE_DEPS
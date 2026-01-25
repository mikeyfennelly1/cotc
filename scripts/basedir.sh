#!/bin/bash

# WARNING TO DEVELOPERS:
#
# The contents of this script should be copied and pasted
# into the script where the following functionality is required.
#
# The purpose of this script (basedir.sh) is to read
# the base directory of the script in use, and set that in
# an environment variable, which is thereafter used as a point of
# relative reference in the script.
#
# All file references without the BASE_DIR env var are considered
# naive, and it would defeat the purpose of this bash code to source
# this through a naive reference (like `source ../commons.sh`).

################################################
# SETUP
################################################
OS=$(uname)
if [[ "$OS" == "Darwin" ]]; then
	# OSX uses BSD readlink
	BASEDIR="$(dirname "$0")"
else
	BASEDIR=$(readlink -e "$(dirname "$0")/")
fi
cd "${BASEDIR}"

source "${BASEDIR}"/../.env
source "${BASEDIR}"/../scripts/helpers.sh

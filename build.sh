#!/bin/bash
#
# This file is part of Builder.
#
# Builder is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Builder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Builder.  If not, see <https://www.gnu.org/licenses/>.
#
set -euo pipefail
BUILDER_PATH="$(diname $(realpath "$0"))"


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Comman line parsing

PACKAGE=${1:help}
shift
case "$PACKAGE"
"*help")
	cat <<ENDHELP
Usage: build <package> <version>

  Some <package> names have a special meaning

      help           this text is printed
      configure      installs ~/.builderrc and exits


  Builder  Copyright (C) 2020  Dennis Terhorst
  This program comes with ABSOLUTELY NO WARRANTY; for details type 'build help'.
  This is free software, and you are welcome to redistribute it
  under certain conditions; see 'LICENSE' for details.
ENDHELP
	exit 0
	;;
esac

if [ -z ${1+x} ]; then
	echo ">>> ERROR: No version specified!"
	exit 1;
fi
VERSION=${1}	# keep version as $1 in $@ to hand it to the build scrips!
VARIANT=${2:-default}	# optional variant

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setup defaults and environment variables

if [ ! -e "${HOME}/.buildrc" ]; then
	cat <<ENDRC
#
# This is the configuration file for Builder
#
# If you use environment or Builder internal variables to define paths, you
# have to escape the dollar '\\\$' to deferr evaluation to the actual build
# time.
#
# Builder internal variables are evaluated in the following order:
# SOURCE, TARGET, BUILD, LOG
# Each definition can reference only preceeding ones.

# storage of all build plans
PLANFILE_PATH=${BUILDER_PATH}/plans

# storage of all package archives (like .tar.gz files)
PACKAGE_CACHE=\\\${HOME}/src

# temporary storage of source files (extracted from tar-balls)
SOURCE_PATH=\\\${HOME}/build/src

# location for out-of-tree builds
BUILD_PATH=\\\${HOME}/build

# install path (usually used as --prefix)
TARGET_PATH=\\\${HOME}/install

# path where to store logfiles of the build
LOG_PATH=\\\${BUILD}/logs
ENDRC
fi

# load configuration
if [ -r "${HOME}/.buildrc" ]; then
	. "${HOME}/.buildrc"
else
	echo "ERROR: Could not read ~/.buildrc"
	exit 1
fi

# load Builder function library
if [ ! -r "${BUILDER_PATH}/build_functions.sh" ]; then
	echo "ERROR: could not find Builder functions!"
	exit 1
fi
. "${BUILDER_PATH}/build_functions.sh"

if [ "${PACKAGE}" == "configure" ]; then
	exit 1
fi

echo ">>> set up build of ${PACKAGE} ${VERSION} (${VARIANT} variant)..."
SOURCE="${SOURCE_PATH@P}/${PACKAGE}-${VERSION}"
TARGET="${TARGET_PATH@P}/${PACKAGE}/${VERSION}"
BUILD="${BUILD_PATH@P}/${PACKAGE}/${VERSION}"
LOG="${LOG_PATH@P}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Load the build plan
PLAN="${PLANFILE_PATH}/${PACKAGE}/${VERSION}/${VARIANT}"
. "${PLAN}"

echo ">>> SOURCE=${SOURCE}"
echo ">>> TARGET=${TARGET}"
echo ">>> BUILD=${BUILD}"
echo ">>> LOG=${LOG}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run build sequence

source_prepare
build_prepare
build_package
build_test
build_install
build_install_test

echo ">>> done."

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
if [ -z "${BUILDER_PATH+x}" ]; then
	BUILDER_PATH="$(dirname "$(realpath "$0")")"
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Comman line parsing

PACKAGE=${1:-help}
shift || true
case "$PACKAGE" in
*help | -h)
	cat <<ENDHELP
Usage: build -h|--help
       build configure
       build <package> [<version>] [<variant>]

  Install software as given in a build plan identifed by <package>, <version>
  and optional <variant>. If no <variant> is given, the "default" variant will
  be built.

Options:

  -h or --help       this text is printed
  configure          installs ~/.buildrc and exits


  Builder  Copyright (C) 2020  Dennis Terhorst, Forschungszentrum Jülich GmbH/INM-6
  This program comes with ABSOLUTELY NO WARRANTY; for details type 'build help'.
  This is free software, and you are welcome to redistribute it under certain
  conditions; see '${BUILDER_PATH}/LICENSE' for details.

ENDHELP
	exit 0
	;;
esac


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Setup Builder configuration

if [ "${PACKAGE}" == "configure" -a -e "${HOME}/.buildrc" ]; then
	cat <<ENDNOTICE
!!!
!!! ~/.buildrc already exists.
!!!
!!! Edit manually or delete it to install a new default configuration.
!!!
ENDNOTICE
fi
if [ ! -e "${HOME}/.buildrc" ]; then
	echo ">>> installing default configuration '${HOME}/.buildrc'..."
	cat >"${HOME}/.buildrc" <<ENDRC
#
# This is the configuration file for Builder
#
# If you use environment or Builder internal variables to define paths, you
# have to escape the dollar '\\\$' to defer evaluation to the actual build
# time.
#
# Builder internal variables are evaluated in the following order:
# SOURCE, TARGET, BUILD, LOG
# Each definition can reference only preceeding ones.

# storage of all build plans
PLANFILE_PATH=${BUILDER_PATH}/plans

# storage of all package archives (like .tar.gz files)
PACKAGE_CACHE=\${HOME}/src

# temporary storage of source files (extracted from tar-balls)
SOURCE_PATH=\${HOME}/build/src

# location for out-of-tree builds
BUILD_PATH=\${HOME}/build

# install path (usually used as --prefix)
TARGET_PATH=\${HOME}/install

# module install path. If defined and a template file
# '<package>/<version>/<variant>.module' exists, it will be filled and copied
# to '<MODULE_INSTALL_PATH>/<package>/<version>/<variant>'.
MODULE_INSTALL_PATH=\${HOME}/modules

# path where to store logfiles of the build
LOG_PATH=\\\${BUILD}/logs

# define the number of cores to use in standard build_package()
#MAKE_THREADS=\$(( \$(nproc) / 4 ))
ENDRC
	cat "${HOME}/.buildrc"
	cat <<ENDNOTE
!!!
!!! You probably want to modify at least the \$TARGET_PATH in your
!!! configuration in '~/.buildrc'.
!!!
ENDNOTE
	echo -e "\n>>> default configuration has been written to"
	echo -e "    ${HOME}/.buildrc\n"
	if [ "$PACKAGE" != "configure" ]; then
		echo "!!! Please check that the guessed paths are correct and"
		echo "!!! rerun the build command."
		echo -e "\n>>> Stopping here, to be sure."
		exit 1
	fi
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


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# set up builder variables for the plan files

if [ -z ${1+x} ]; then
	log_warning ">>>"
	log_warning ">>> No version specified!"
	guess="$(ls -1 "${PLANFILE_PATH}/${PACKAGE}" | grep '^[0-9]\+\.[0-9]\+.*' | sort -V | tail -n1)"
	log_warning ">>> Guessing you want the latest available version:"
	log_warning ">>>    ${PACKAGE}-${guess}"
	log_warning ">>>"
	VERSION="${guess}"
else
	VERSION="${1}"	# keep version as $1 in $@ to hand it to the build scrips!
fi
VARIANT="${2:-default}"	# optional variant
log_status ">>> set up build of ${PACKAGE} ${VERSION} (${VARIANT} variant)..."

if version_gt $BASH_VERSION 4.4; then
	SOURCE="${SOURCE_PATH@P}/${PACKAGE}-${VERSION}"
	TARGET="${TARGET_PATH@P}/${PACKAGE}/${VERSION}_${VARIANT}"
	BUILD="${BUILD_PATH@P}/${PACKAGE}/${VERSION}/${VARIANT}"
	LOG="${LOG_PATH@P}"
else
	SOURCE="$(eval echo "${SOURCE_PATH}/${PACKAGE}-${VERSION}")"
	TARGET="$(eval echo "${TARGET_PATH}/${PACKAGE}/${VERSION}")"
	BUILD="$(eval echo "${BUILD_PATH}/${PACKAGE}/${VERSION}/${VARIANT}")"
	LOG="$(eval echo "${LOG_PATH}")"
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Load the build plan
log_status ">>> loading the build plan..."
PLAN="${PLANFILE_PATH}/${PACKAGE}/${VERSION}/${VARIANT}"
. "${PLAN}"

log_status ">>> build environment information"
builder_info

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run build sequence
log_success "\nPRESS ENTER TO START"
read

source_prepare
build_prepare
build_package
build_test
build_install
build_install_test
module_install

log_success ">>>\n>>> done.\n>>>"

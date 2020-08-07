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

################################################################################
# Helper functions

split_ext() {
	case "$1" in
	*.tar.bz2) echo ".tar.bz2" ;;
	*.tar.gz) echo ".tar.gz" ;;
	*.tar.xz) echo ".tar.xz" ;;
	*.tgz) echo ".tgz" ;;
	*.zip) echo ".zip" ;;
	*) echo "UNKNOWN EXTENSION OF FILE '$1'"; exit 1;
	esac
}

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

builder_info () {
	echo "Configured variables:"
	echo "  PLANFILE_PATH=${PLANFILE_PATH:- <undefined>}"
	echo "  PACKAGE_CACHE=${PACKAGE_CACHE:- <undefined>}"
	echo "  SOURCE_PATH=${SOURCE_PATH:- <undefined>}"
	echo "  BUILD_PATH=${BUILD_PATH:- <undefined>}"
	echo "  TARGET_PATH=${TARGET_PATH:- <undefined>}"
	echo "  MODULE_INSTALL_PATH=${MODULE_INSTALL_PATH:- <undefined>}"
	echo "  LOG_PATH=${LOG_PATH:- <undefined>}"
	echo ""
	echo "Build Variables:"
	echo "  PACKAGE=${PACKAGE:- <undefined>}"
	echo "  VERSION=${VERSION:- <undefined>}"
	echo "  VARIANT=${VARIANT:- <undefined>}"
	echo "  PLAN=${PLAN:- <undefined>}"
	echo "  SOURCE=${SOURCE:- <undefined>}"
	echo "  TARGET=${TARGET:- <undefined>}"
	echo "  BUILD=${BUILD:- <undefined>}"
	echo "  LOG=${LOG:- <undefined>}"
}
################################################################################
# Default implementation of steps

source_prepare() {
	EXT="$(split_ext "${URL}")"
	PACKAGE_FILE="${PACKAGE_CACHE}/${PACKAGE}-${VERSION}${EXT}"
	mkdir -pv "$(dirname "$PACKAGE_FILE")"
	echo ">>> prepare source"
	if [ ! -r "${PACKAGE_FILE}" ]; then
		echo ">>> downloading $(basename "${PACKAGE_FILE}") from ${URL}"
		wget "$URL" -O "${PACKAGE_FILE}"
	fi
	if [ ! -d $SOURCE ]; then
		mkdir -pv $(dirname $SOURCE)
		cd $(dirname $SOURCE)
		echo "extracting ${PACKAGE_FILE}"
		case "$(basename "${URL}")" in
		    *.tar.gz | *.tgz)
			tar -xzf "${PACKAGE_FILE}"
			;;
		    *.tar.bz2 | *.tbz)
			tar -xjf "${PACKAGE_FILE}"
			;;
		    *.tar.xz)
			tar -xJf "${PACKAGE_FILE}"
			;;
		    *.zip)
			unzip "${PACKAGE_FILE}"
			;;
		    *)
			echo "NO RULE HOW TO EXTRACT '${PACKAGE_FILE}'";
			exit 1;
		esac
	fi
}

build_prepare() {
	echo ">>> prepare build"
	if [ -d "$BUILD" ]; then
		read -p "sure you want to delete $BUILD? (ctrl-c for NO)"
		rm -vrf "$BUILD"
	fi
	mkdir -pv "$BUILD"
	mkdir -pv "$LOG"
}

build_package () {
	echo ">>> build"
	cd $BUILD
	set -x
	./configure --prefix="$TARGET" |& tee ${LOG}/configure.log
	make -j $(( $(nproc) / 4 )) |& tee ${LOG}/make.log
}

build_test () {
	echo ">>> no tests defined."
}

build_install () {
	make install |& tee ${LOG}/make-install.log
}

module_install () {
	if [ -r "${PLAN}.module" ]; then
		module_path="${MODULE_INSTALL_PATH}/${PACKAGE}/${VERSION}/${VARIANT}"
		echo ">>> installing module file to ${module_path}"
		module="$(cat "${PLAN}.module")"
		echo "${module@P}" >"${module_path}"
	else
		echo ">>> no modulefile template found. skipping."
	fi
}

build_install_test () {
	echo ">>> no install-tests defined."
}

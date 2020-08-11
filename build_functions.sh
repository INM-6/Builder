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

log_status() { /usr/bin/echo -e "\033[00;34m${@}\033[0m"; }
log_info() { /usr/bin/echo -e "\033[00;33m${@}\033[0m"; }

log_error() { /usr/bin/echo -e "\033[01;41m${@}\033[0m"; }

log_warning() { /usr/bin/echo -e "\033[01;31m${@}\033[0m"; }

split_ext() {
	case "$1" in
	*.tar.bz2) echo ".tar.bz2" ;;
	*.tar.gz) echo ".tar.gz" ;;
	*.tar.xz) echo ".tar.xz" ;;
	*.tgz) echo ".tgz" ;;
	*.zip) echo ".zip" ;;
	*) log_error "UNKNOWN EXTENSION OF FILE '$1'"; exit 1;
	esac
}

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

builder_info () {
	log_info "Configured variables:"
	log_info "  PLANFILE_PATH=${PLANFILE_PATH:- <undefined>}"
	log_info "  PACKAGE_CACHE=${PACKAGE_CACHE:- <undefined>}"
	log_info "  SOURCE_PATH=${SOURCE_PATH:- <undefined>}"
	log_info "  BUILD_PATH=${BUILD_PATH:- <undefined>}"
	log_info "  TARGET_PATH=${TARGET_PATH:- <undefined>}"
	log_info "  MODULE_INSTALL_PATH=${MODULE_INSTALL_PATH:- <undefined>}"
	log_info "  LOG_PATH=${LOG_PATH:- <undefined>}"
	log_info ""
	log_info "Build Variables:"
	log_info "  PACKAGE=${PACKAGE:- <undefined>}"
	log_info "  VERSION=${VERSION:- <undefined>}"
	log_info "  VARIANT=${VARIANT:- <undefined>}"
	log_info "  PLAN=${PLAN:- <undefined>}"
	log_info "  SOURCE=${SOURCE:- <undefined>}"
	log_info "  TARGET=${TARGET:- <undefined>}"
	log_info "  BUILD=${BUILD:- <undefined>}"
	log_info "  LOG=${LOG:- <undefined>}"
}
################################################################################
# Default implementation of steps

source_prepare() {
	EXT="$(split_ext "${URL}")"
	PACKAGE_FILE="${PACKAGE_CACHE}/${PACKAGE}-${VERSION}${EXT}"
	mkdir -pv "$(dirname "$PACKAGE_FILE")"
	log_status ">>> prepare source"
	if [ ! -r "${PACKAGE_FILE}" ]; then
		log_status ">>> downloading $(basename "${PACKAGE_FILE}") from ${URL}"
		wget "${URL}" -O "${PACKAGE_FILE}"
		if [ ! -z "${GPG_VERIFY_KEY-x}" ]; then
			# if a verify key is defined, fetch signature and check it
			wget "${URL}.sig" -O "${PACKAGE_FILE}.sig"
			gpg --import gsl_key.txt
			( cd "${PACKAGE_CACHE}";
			  gpg --verify "$(basename ${PACKAGE_FILE}).sig" )
		fi

	fi
	if [ ! -d $SOURCE ]; then
		mkdir -pv $(dirname $SOURCE)
		cd $(dirname $SOURCE)
		log_info "extracting ${PACKAGE_FILE}"
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
			log_error "NO RULE HOW TO EXTRACT '${PACKAGE_FILE}'";
			exit 1;
		esac
	fi
}

build_prepare() {
	log_status ">>> prepare build"
	if [ -d "${BUILD}" ]; then
		read -p "sure you want to delete ${BUILD}? (ctrl-c for NO)"
		rm -vrf "${BUILD}"
	fi
	mkdir -pv "${BUILD}"
	mkdir -pv "${LOG}"
}

build_package () {
	log_status ">>> build"
	cd "${BUILD}"
	set -x
	./configure --prefix="${TARGET}" --srcdir="${SOURCE}" |& tee "${LOG}/configure.log"
	make -j $(( $(nproc) / 4 )) |& tee "${LOG}/make.log"
	set +x
}

build_test () {
	log_status ">>> no tests defined."
}

build_install () {
	make install |& tee ${LOG}/make-install.log
}

module_install () {
	if [ -r "${PLAN}.module" ]; then
		module_path="${MODULE_INSTALL_PATH}/${PACKAGE}/${VERSION}/${VARIANT}"
		log_status ">>> installing module file to ${module_path}"
		mkdir -pv "$(dirname ${module_path})"
		module="$(cat "${PLAN}.module")"
		if version_gt $BASH_VERSION 4.4; then
			echo "${module@P}" >"${module_path}"
		else
			# this is a bad substitute for the power of the bash>4.4 notation.
			echo "${module}" | sed \
			    -e 's%\\\$%__NOT_BUILDER_DOLLAR__%g' \
			    -e "s%\${\?PLANFILE_PATH}\?%$PLANFILE_PATH%g" \
			    -e "s%\${\?PACKAGE_CACHE}\?%$PACKAGE_CACHE%g" \
			    -e "s%\${\?SOURCE_PATH}\?%$SOURCE_PATH%g" \
			    -e "s%\${\?BUILD_PATH}\?%$BUILD_PATH%g" \
			    -e "s%\${\?TARGET_PATH}\?%$TARGET_PATH%g" \
			    -e "s%\${\?MODULE_INSTALL_PATH}\?%$MODULE_INSTALL_PATH%g" \
			    -e "s%\${\?LOG_PATH}\?%$LOG_PATH%g" \
			    -e "s%\${\?PACKAGE}\?%$PACKAGE%g" \
			    -e "s%\${\?VERSION}\?%$VERSION%g" \
			    -e "s%\${\?VARIANT}\?%$VARIANT%g" \
			    -e "s%\${\?PLAN}\?%$PLAN%g" \
			    -e "s%\${\?SOURCE}\?%$SOURCE%g" \
			    -e "s%\${\?TARGET}\?%$TARGET%g" \
			    -e "s%\${\?BUILD}\?%$BUILD%g" \
			    -e "s%\${\?LOG}\?%$LOG%g" \
			    -e 's%__NOT_BUILDER_DOLLAR__%$%g' \
			       > "${module_path}"
		fi
		if ! echo "${MODULE_INSTALL_PATH}" | grep "${MODULEPATH}"; then
			log_info ">>>"
			log_info ">>> Info: MODULE_INSTALL_PATH is not in your MODULEPATH"
			log_info ">>>       You may want to add the following line to your startup"
			log_info ">>>       scripts like ~/.bashrc:"
			log_info ">>>"
			log_info ">>>       export MODULEPATH=\$MODULEPATH:${MODULE_INSTALL_PATH}"
			log_info ">>>"
		fi
	else
		log_status ">>> no modulefile template found. skipping."
	fi
}

build_install_test () {
	log_status ">>> no install-tests defined."
}

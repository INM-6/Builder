#!/bin/bash
#
# Builder – Compile scripts for local installs of software packages.
# Copyright (C) 2020 Forschungszentrum Jülich GmbH, INM-6
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
# SPDX-License-Identifier: GPL-3.0-or-later
#

################################################################################
# Helper functions

ECHO="$(command -v echo)"
log_info() { "$ECHO" -e "\033[00;34m${@}\033[0m"; }
log_status() { "$ECHO" -e "\033[01;33m${@}\033[0m"; }
log_error() { "$ECHO" -e "\033[01;41m${@}\033[0m"; }
log_warning() { "$ECHO" -e "\033[01;31m${@}\033[0m"; }
log_success() { "$ECHO" -e "\033[00;32m${@}\033[0m"; }

split_ext() {
	case "$1" in
	*.tar.bz2) echo ".tar.bz2" ;;
	*.tar.gz) echo ".tar.gz" ;;
	*.tar.xz) echo ".tar.xz" ;;
	*.tgz) echo ".tgz" ;;
	*.zip) echo ".zip" ;;
	*.jar) echo ".jar" ;;
	*) log_error "UNKNOWN EXTENSION OF FILE '$1'"; exit 1;
	esac
}

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

builder_info () {
	log_info "Configured variables:"
	log_info "  PLANFILE_PATH=\"${PLANFILE_PATH:- <undefined>}\""
	log_info "  PACKAGE_CACHE=\"${PACKAGE_CACHE:- <undefined>}\""
	log_info "  SOURCE_PATH=\"${SOURCE_PATH:- <undefined>}\""
	log_info "  BUILD_PATH=\"${BUILD_PATH:- <undefined>}\""
	log_info "  TARGET_PATH=\"${TARGET_PATH:- <undefined>}\""
	log_info "  MODULE_INSTALL_PATH=\"${MODULE_INSTALL_PATH:- <undefined>}\""
	log_info "  LOG_PATH=\"${LOG_PATH:- <undefined>}\""
	log_info "  MAKE_THREADS=\"${MAKE_THREADS:- <undefined>}\""
	log_info ""
	log_info "Build Variables:"
	log_info "  PACKAGE=\"${PACKAGE:- <undefined>}\""
	log_info "  VERSION=\"${VERSION:- <undefined>}\""
	log_info "  VARIANT=\"${VARIANT:- <undefined>}\""
	log_info "  PLAN=\"${PLAN:- <undefined>}\""
	log_info "  SOURCE=\"${SOURCE:- <undefined>}\""
	log_info "  TARGET=\"${TARGET:- <undefined>}\""
	log_info "  BUILD=\"${BUILD:- <undefined>}\""
	log_info "  LOG=\"${LOG:- <undefined>}\""
	log_info ""
	log_info "  CONFIGURE_OPTIONS=\"${CONFIGURE_OPTIONS:- <undefined>}\""
}
################################################################################
# Default implementation of steps


check_package_file() {
	log_status ">>> checking ${PACKAGE_FILE}..."
	# One section for each algorithm that can check the file.
	# put weakest algorithms first, so $strength can be overwritten if also stronger checks exist
	checked=false
	strength="strong"
	if [ ! -z "${MD5SUM+x}" ]; then
		echo -n "MD5: "
		md5sum -c <<<"${MD5SUM}  ${PACKAGE_FILE}"
		checked=true
		strength="MD5"
	fi
	if [ ! -z "${SHA1SUM+x}" ]; then
		echo -n "SHA1: "
		sha1sum -c <<<"${SHA1SUM}  ${PACKAGE_FILE}"
		checked=true
		strength="SHA1"
	fi
	if [ ! -z "${SHA224SUM+x}" ]; then
		echo -n "SHA224: "
		sha224sum -c <<<"${SHA224SUM}  ${PACKAGE_FILE}"
		checked=true
		strength="strong"
	fi
	if [ ! -z "${SHA256SUM+x}" ]; then
		echo -n "SHA256: "
		sha256sum -c <<<"${SHA256SUM}  ${PACKAGE_FILE}" || { echo""; echo "🚨  ERROR: UNEXPECTED PACKAGE CONTENT!";  echo; false; }
		checked=true
		strength="strong"
	fi
	if [ ! -z "${SHA384SUM+x}" ]; then
		echo -n "SHA384: "
		sha384sum -c <<<"${SHA384SUM}  ${PACKAGE_FILE}"
		checked=true
		strength="strong"
	fi
	if [ ! -z "${SHA512SUM+x}" ]; then
		echo -n "SHA512: "
		sha512sum -c <<<"${SHA512SUM}  ${PACKAGE_FILE}"
		checked=true
		strength="strong"
	fi
	if [ ! -z "${GPG_VERIFY_KEY+x}" ]; then
		# if a verify key is defined, fetch signature and check it
		if [ ! -r "${PACKAGE_FILE}.sig" ]; then
			wget "${URL}.sig" -O "${PACKAGE_FILE}.sig"
			gpg --import "$(dirname "${PLAN}")/${GPG_VERIFY_KEY}"
		fi
		echo -n "GPG Signature: "
		( cd "${PACKAGE_CACHE}";
		  gpg --verify "$(basename "${PACKAGE_FILE}").sig" )
		checked=true
		strength="strong"
	fi
	if $checked; then
		if [ "$strength" == "strong" ]; then
			log_success "... package checked! 👍"
		else
			log_warning "!!!"
			log_warning "!!! Using only weak ${strength} checksum. This does not protect the package against tampering!"
			log_warning "!!!"
			sleep 5
		fi
	else
		log_warning "!!!"
		log_warning "!!! PACKAGE FILE WAS NOT CHECKED!"
		log_warning "!!!"
		log_warning "!!! This means, that package content may change unnoticed,"
		log_warning "!!! including modifications with possibly malicious intent."
		log_warning "!!!"
		log_warning "!!! Add a checksum or signature to the plan file!"
		log_warning "!!!"
		sleep 10
	fi
}

source_get() {
	# This function takes the PACKAGE_FILE, checks it and puts the
	# contained source code into the SOURCE directory
	log_status ">>> prepare source"
	EXT="$(split_ext "${URL}")" || { echo "$EXT"; false; }
	PACKAGE_FILE="${PACKAGE_CACHE}/${PACKAGE}-${VERSION}${EXT}"
	mkdir -pv "$(dirname "${PACKAGE_FILE}")"
	if [ ! -r "${PACKAGE_FILE}" ]; then
		log_status ">>> downloading $(basename "${PACKAGE_FILE}") from ${URL}"
		wget "${URL}" -O "${PACKAGE_FILE}"
	fi
}

source_prepare() {
	check_package_file

	if [ -d "${SOURCE}" ] && [ $FORCE = true ] ; then
		read -p "sure you want to delete ${SOURCE}? (ctrl-c for NO)"
		rm -vrf "${SOURCE}"
	fi

	if [ ! -d "${SOURCE}" ]; then
		mkdir -pv "${SOURCE}"
		cd "${SOURCE}"
		log_info "extracting ${PACKAGE_FILE}"
		case "$(basename "${URL}")" in
		    *.tar.gz | *.tgz)
			tar -xzf "${PACKAGE_FILE}" --strip-components=1
			;;
		    *.tar.bz2 | *.tbz)
			tar -xjf "${PACKAGE_FILE}" --strip-components=1
			;;
		    *.tar.xz)
			tar -xJf "${PACKAGE_FILE}" --strip-components=1
			;;
		    *.zip)
			unzip "${PACKAGE_FILE}"
			cd "$SOURCE"
			rsync -ua --delete-after */ .
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
		if  [ $FORCE = false ] && [ $SILENT = false ] ; then
			read -p "sure you want to delete ${BUILD}? (ctrl-c for NO)"
			rm -vrf "${BUILD}"
		elif [ $SILENT = true ]; then
			log_status ">>> skip build (use -f for force build)"
		else
			rm -vrf "${BUILD}"
		fi
	fi
	mkdir -pv "${BUILD}"
	mkdir -pv "${LOG}"
}

build_package () {
	log_status ">>> build ${PACKAGE}/${VERSION}/${VARIANT}..."
	cd "${BUILD}"
	set -x
	"${SOURCE}/configure" --prefix="${TARGET}" --srcdir="${SOURCE}" ${CONFIGURE_OPTIONS:-} 2>&1 | tee "${LOG}/configure.log"
	make -j ${MAKE_THREADS:-$(nproc)} 2>&1 | tee "${LOG}/make.log"
	set +x
}

build_test () {
	log_status ">>> no tests defined."
}

build_install () {
	log_status ">>> installing..."
	make install 2>&1 | tee "${LOG}/make-install.log"
}

module_capture_prereq () {
	# This function returns the module system "prereq" lines
	# built from the curently loaded modules listed in `$LOADEDMODULES`
	MODULES="${LOADEDMODULES:-}"
	for dep in ${MODULES//:/ }; do
		if echo "$dep" | grep "Builder" >/dev/null; then
			# nothing should ever automatically depend on builder
			# so we skip this dependency.
			continue;
		fi
		echo -n "module load $dep\\n"
	done
}

module_install () {
	AUTOMATIC_BUILD_WARNING=" This file was automatically produced by Builder.\n# Any changes may be overwritten without notice.\n#\n# Please see ${BUILDER_PATH} for details."

	PREREQ_DEPENDS="$(module_capture_prereq)"
	if [ -r "${PLAN}.module" ]; then
		module_path="${MODULE_INSTALL_PATH}/${PACKAGE}/${VERSION}/${VARIANT}"
		#PYTHON_SCRIPTS="$(python -c "import sysconfig; print(sysconfig.get_path('scripts'))")"
		#PYTHON_PLATLIB="$(python -c "import sysconfig; print(sysconfig.get_path('platlib'))")"
		#PYTHON_PURELIB="$(python -c "import sysconfig; print(sysconfig.get_path('purelib'))")"
		#PYTHON_SITEPKG="$(python -c "import sysconfig; from pathlib import Path; print(Path(sysconfig.get_path('purelib')).relative_to(sysconfig.get_path('data')))")"
		log_status ">>> installing module file to ${module_path}"
		mkdir -pv "$(dirname "${module_path}")"
		module="$(cat "${PLAN}.module")"
		if version_gt $BASH_VERSION 4.4; then
			echo -e "${module@P}" >"${module_path}"
		else
			# this is a bad substitute for the power of the bash>4.4 notation.
			echo "${module}" | sed \
			    -e 's%\\\$%__NOT_BUILDER_DOLLAR__%g' \
			    -e "s%\${\?AUTOMATIC_BUILD_WARNING}\?%$AUTOMATIC_BUILD_WARNING%g" \
			    -e "s%\${\?BUILDER_PATH}\?%$BUILDER_PATH%g" \
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
			    -e "s%\${\?PREREQ_DEPENDS}\?%$PREREQ_DEPENDS%g" \
			    -e "s%\${\?VIRTUAL_ENV}\?%${VIRTUAL_ENV:-/}%g" \
			    -e 's%__NOT_BUILDER_DOLLAR__%$%g' \
			       > "${module_path}"
			    #-e "s%\${\?PYTHON_SCRIPTS}\?%$PYTHON_SCRIPTS%g" \
			    #-e "s%\${\?PYTHON_PLATLIB}\?%$PYTHON_PLATLIB%g" \
			    #-e "s%\${\?PYTHON_PURELIB}\?%$PYTHON_PURELIB%g" \
			    #-e "s%\${\?PYTHON_SITEPKG}\?%$PYTHON_SITEPKG%g" \
		fi
		if ! echo "${MODULEPATH:-}" | grep "${MODULE_INSTALL_PATH}" >/dev/null; then
			log_info ">>>"
			log_info ">>> Info: MODULE_INSTALL_PATH is not in your MODULEPATH"
			log_info ">>>       You may want to add a line like the following to your startup"
			log_info ">>>       scripts like ~/.bashrc:"
			log_info ">>>"
			log_info ">>>       export MODULEPATH=${MODULE_INSTALL_PATH}:\$MODULEPATH"
			log_info ">>>"
		else
			log_success ">>> use 'module avail' to see and e.g. 'module load ${PACKAGE}/${VERSION}' to load modules."
		fi
	else
		log_status ">>> no modulefile template found. skipping."
	fi
}

build_install_test () {
	log_status ">>> no install-tests defined."
}

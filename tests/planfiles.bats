#!/usr/bin/env bats
load test_helper

test_files_contain() {
	# This helper function seaches for all files matching $2 pattern
	# and complains about those not matching $1 regex.
	DEP_LINE="$1"
	DEP_PAT="$2"
	N_BAD=0
	for file in $(find "$BATS_TEST_DIRNAME/../" -name "${DEP_PAT}"); do
		egrep "${DEP_LINE}" "${file}" >/dev/null || {
			echo "$file does not contain ${DEP_LINE}";
			N_BAD=$(( $N_BAD + 1 ))
		};
	done
	[ $N_BAD -eq 0 ] || {
		echo "$N_BAD BAD FILES"
		false
	}
}

test_planfiles_startwith() {
	# This helper function seaches for all files matching $2 pattern
	# and complains about those not matching $1 regex.
	FILESTART="$1"
	NLINES="$(echo "$FILESTART" | wc -l)"
	N_BAD=0
	for file in $(find "$BATS_TEST_DIRNAME/../plans" -type f -not -name "*.module" -not -name "*.txt" -not -name "*.sw*"); do
		[ "$FILESTART" = "$(head -n $NLINES "$file")" ] || {
			echo "$file does not contain correct copyright statement";
			echo ""
			head -n $NLINES "$file" | diff -u /dev/stdin --label "$file" /dev/fd/9 --label "correct" 9<<<"$FILESTART"
			echo ""
			N_BAD=$(( $N_BAD + 1 ))
		};
	done
	[ $N_BAD -eq 0 ] || {
		echo "$N_BAD BAD FILES"
		false
	}
}

@test "modules contain 'PREREQ_DEPENDS'" {
	run test_files_contain 'PREREQ_DEPENDS' "*.module"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
Usually a package depends on other loaded modules. To configure the module
system to announce unmet prerequisites, place a "\${PREREQ_DEPENDS}" line in
the file. In the unusual case that you do not want the dependencies listed,
remove the initial '\$', comment it out and explain why it is not needed, but
don't remove the line.
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

@test "modules contain 'automatic build warning'" {
	run test_files_contain '# \$\{AUTOMATIC_BUILD_WARNING\}' "*.module"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
Module files should contain the variable "# \${AUTOMATIC_BUILD_WARNING}" to
mark them as being potentially overwritten.
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

@test "modules contain 'conflict' clause" {
	run test_files_contain 'conflict \$\{PACKAGE\}' "*.module"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
Usually a package can only be loaded once. To configure the module system to
announce a conflict if a package has already been loaded, place a "conflict"
line in the file. In the unusual case that you do not want the conflict line,
comment it out and explain why it is not needed, but don't remove the line.
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

@test "modules contain quoted TARGET path" {
	run test_files_contain "\"${TARGET}" "*.module"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
In order to support filenames with spaces, expansion of \${TARGET} needs to be
in quotes.
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

@test "modules contain module-whatis" {
	run test_files_contain "^module-whatis +\"" "*.module"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
A module template shuld anounce it's short description in a 'whatis' line.
See e.g.
https://modules.readthedocs.io/en/latest/modulefile.html?highlight=whatis#mfcmd-module-whatis
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

@test "check planfiles start with LICENSE header" {
	FILESTART="#!/bin/bash
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
#"

	run test_planfiles_startwith "$FILESTART"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
Planfiles that are part of builder should start with an appropriate copyright
header. Please open any planfile and copy the first 16 lines verbatim into any
new planfile.
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

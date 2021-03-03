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


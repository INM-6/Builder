#!/usr/bin/env bats

@test "pass shellcheck static code analysis" {
	# Covered by strict mode (set -euo pipefail)
	# SC2164: Use 'cd ... || exit' or 'cd ... || return' in case cd fails.
	# SC2034: <variablename> appears unused. Verify it or export it.
	export SHELLCHECK_OPTS='--exclude=SC2034,SC2164'
	shellcheck $(find plans/ -type f -not -name "*.txt" -a -not -name "*.module" )
}

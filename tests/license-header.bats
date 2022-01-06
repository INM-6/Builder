#!/usr/bin/env bats
load test_helper

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

test_codefiles_startwith() {
	# This helper function seaches for all files matching $2 pattern
	# and complains about those not matching $1 regex.
	FILESTART="$1"
	NLINES="$(echo "$FILESTART" | wc -l)"
	N_BAD=0
	for file in $(find "$BATS_TEST_DIRNAME/.." -maxdepth 2 -type f -name "*.sh"); do
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

@test "check planfiles start with LICENSE header" {
	run test_planfiles_startwith "$(<license-header.txt)"
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

@test "check source code starts with LICENSE header" {
	run test_codefiles_startwith "$(<license-header.txt)"
	if [ ${status} -ne 0 ]; then
		cat <<EOT
---------------------------------------------------------------------------
Source code that are part of builder should start with an appropriate copyright
header. Please make sure each file starts exactly (!) with the content of the
file "tests/license-header.txt"
---------------------------------------------------------------------------
EOT
		emit_debug_output && return 1
	fi
}

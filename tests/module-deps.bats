#!/usr/bin/env bats

load ../build_functions.sh

@test "addition using bc" {
	result="$(echo 2+2 | bc)"
	[ "$result" -eq 4 ]
}

setup() {
	# load two example modules
	module purge
	MODULEPATH="${BATS_TEST_DIRNAME}/modules${MODULEPATH:+:$MODULEPATH}"
	module load somemodule othermodule

	# define base file for comparisons
	modulefile="${BATS_TEST_DIRNAME}/modules/module.template"

	# Create some temporary files
	TMP1="$(mktemp)"
	TMP2="$(mktemp)"

	cat >"$TMP1" <<EOT
#%Module1.0#####################################################################
# module template that can not be loaded
# This is nop-tool/1.0/default
conflict nop-tool
prereq somemodule
prereq othermodule

# eof
EOT
}

teardown() {
	rm -vf "$TMP1" "$TMP2" || echo "failed to remove temporary files $TMP1 and $TMP2"
}

@test "capturing of loaded modules" {
	run module_capture_prereq
	[ "${output}" = "prereq somemodule\nprereq othermodule\n" ]
}

@test "fill module template (old path)" {
	# capture modules, load some dummy variables
	PREREQ_DEPENDS="$(module_capture_prereq)"
	TARGET=/path/to/nop-tool
	VERSION=1.0
	VARIANT=default
	PACKAGE=nop-tool

	# old bash version
	sed -e "s%\${\?PREREQ_DEPENDS}\?%$PREREQ_DEPENDS%g" \
	    -e "s%\${\?TARGET}\?%$TARGET%g" \
	    -e "s%\${\?VERSION}\?%$VERSION%g" \
	    -e "s%\${\?VARIANT}\?%$VARIANT%g" \
	    -e "s%\${\?PACKAGE}\?%$PACKAGE%g" \
            "$modulefile" >"$TMP2"

	# test for both results to be the same
	diff -u "$TMP1" "$TMP2"
}

@test "fill module template (new path)" {
	if ! version_gt $BASH_VERSION 4.4; then
		skip "need at least bash version 4.4 but found $(bash --version)"
	fi
	# capture modules, load some dummy variables
	PREREQ_DEPENDS="$(module_capture_prereq)"
	TARGET=/path/to/nop-tool
	VERSION=1.0
	VARIANT=default
	PACKAGE=nop-tool

	# new bash version
	module="$(cat "$modulefile")"
	echo -e "${module@P}" >"$TMP2"

	# test for both results to be the same
	diff -u "$TMP1" "$TMP2"
}


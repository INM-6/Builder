# Making a Plan

  A build plan defines package specific variables that are used in the build
  steps. In a build plan you can override the default implementations of the
  single steps, that are executed in the following order:

  ----------------------------------------------------------------
  Function            Description
  ------------------  --------------------------------------------
  source_prepare      check the package cache and download the
                      package if it is not found there, and
                      extract sources into $SOURCE directory.

  build_prepare       make sure the build space is available and
                      clean.

  build_package       build the package (usually `configure` and
                      `make`)

  build_test          run any checks on the build (default: do
                      nothing)

  build_install       install the package into $TARGET directory
                      (usually `make install`)

  build_install_test  any tests of the installed package (default:
                      do nothing)
  ----------------------------------------------------------------

  To customize a function, a good starting point is to copy the default
  implementation from `build_functions.sh` into your plan file.

  Formulate a new implementation of a build step in terms of the following
  variables

  Variable   Description
  ---------  ---------------------------------------------
  SOURCE     root directory of the extracted source tree
  TARGET     target install path (use as --prefix)
  BUILD      empty build directory for out-of-tree builds
  LOG        directory to write arbitrary log files

  Builder defines these variables based on some of the variables in the plan
  build_install_test file, of which all are also available in the build steps.

  Additionally, various helper functions, e.g. for version comparisons are
  available from `build_functions.sh`.



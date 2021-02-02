# Making a Plan

## Collection of Plans

  Builder uses plan definitions that are in a different file for each specific
  package build. The files are located in the `$PLANFILE_PATH` always in a
  structure of `<packagename>/<version>/<variant>`, where package name and
  version are obvious, and the `<variant>` allows for different build flags,
  code modifications, etc. If the `<variant>` is not given it is set to
  `default`.

  The plan files are part of Builder, but you can easily choose to create your
  own repository of plans somewhere and set `PLANFILE_PATH` in `.buildrc`
  accordingly.

  The tree of plan files looks something like this

    plans
    ├── cmake
    │   └── 3.18.0
    │       └── default
    ├── gsl
    │   ├── 2.6
    │   │   └── default
    │   └── gsl_key.txt
    ├── libtool
    │   └── 2.4.6
    │       └── default
    ├── nest-simulator
    │   ├── 2.14.0
    │   │   └── default -> ../common
    │   ├── 2.16.0
    │   │   └── default -> ../common
    │   ├── 2.18.0
    │   │   └── default -> ../common
    │   ├── 2.20.0
    │   │   └── default -> ../common
    │   └── common
    ├── python
    │   └── 3.8.5
    │       └── default
    └── tree
        └── 1.8.0
            └── default

  As long as the `<packagename>/<version>/<variant>` structure is there, you
  can use any scheme of symbolic links, includes, ... to reduce duplication of
  code. Keeping the plan files concise, containing only the minimum of
  necessary information, is important to keep the plan files maintainable.


## Plan Files

  A build plan defines package specific variables that are used in the build
  steps. In a build plan you can override the default implementations of the
  single steps, that are executed in the following order (to verify the order
  look at the last lines of `build.sh`):

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

    module_install      fills the modulefile template and copies it
                        to `<MODULE_INSTALL_PATH>/<pkg>/<ver>/<var>`
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

  **Hint:** For easier debugging you can type e.g. `build yourpackage` then
  cancel with `ctrl-c`. On the screen you find the blue sections with
  variable definitions as interpreted by Builder. Copy&paste them to your
  shell, then it's easy to move around with `cd $BUILD`, `cd $SOURCE`, etc.

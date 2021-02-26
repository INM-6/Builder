# Builder Configuration

  Builder is designed to require only very minimal configuration. Upon its
  first build or when explicitly called with `build configure` a file
  `.buildrc` is created if it does not exist yet. This file contains variables
  that define various locations used in the build and install process.  When
  the file is generated automatically Builder pre-fills some guessed defaults
  that point to your home directory. While this quickly gets you started,
  installing a lot of software into your `$HOME` is usually not a good idea and
  you should set `$TARGET_PATH` to a better location.

  The builder configuration defines variables of the build system itself.
  Mostly paths where Builder can put its work-space and where to put the
  building materials and resulting packages.

  On every build, the specific places are derived from the configured ones.
  Before starting to do anything Builder shows the *configured variables* as it
  understood from the configuration and *build variables* as it calculated for
  the specific task at hand. You can cross check all settings and for debugging
  it is easily possible to copy-and-paste variables into your shell.


## `.buildrc` variables

  Builder configuriation is automatically loaded from `$HOME/.buildrc`. If this
  file does not exist, it will be created and the build will abort for you to
  check the settings. The variables expected to be available after sourcing
  `.buildrc` are described in the following table. The variables marked
  "optional", if undefined, will be filled with appropriate default values by
  builder for each build.

  Note that the expressions need not be constants, but are evaluated according
  to normal bash expansion rules (see man bash(1)). By this, you can
  automatically set project specific directories, calculate the available
  number of threads, time-stamp temporary directories, etc.


------------------------------------------------------------------------------
Vaiable                Description
-----------------      -------------------------------------------------------
`PLANFILE_PATH`        storage of all build plans

`PACKAGE_CACHE`        storage of all package archives (like `.tar.gz` files)

`SOURCE_PATH`          temporary storage of source files (extracted from
                       tar-balls)

`BUILD_PATH`           Main working area of Builder. Location for out-of-tree
                       builds. In-tree builds will copy or move source code
                       here.

`TARGET_PATH`          Base install path of packages used to construct the
                       `TARGET` directory

`MODULE_INSTALL_PATH`  (optional) If defined and a template file
                       `<package>/<version>/<variant>.module` exists, it will
                       be filled and copied to
                       `<MODULE_INSTALL_PATH>/<package>/<version>/<variant>`

`LOG_PATH`             Path where to store logfiles of the build. These are
                       mainly useful for debugging purposes.

`MAKE_THREADS`         (optional) Defines the number of cores to use in
                       standard `build_package()`
------------------------------------------------------------------------------


### Important notes about paths

  * `SOURCE_PATH` and `BUILD_PATH` are probably best suited on a fast file
    system. Both are ephemeral and could be local /tmp or scratch space.
    Important to know is also, that most builds clear the `BUILD_PATH` before
    starting to work, so defining `SOURCE_PATH` in a sub-directory of the
    `BUILD_PATH` will also re-extract the package sources each time. Some plans
    however may not work well with nested folders (e.g. a plan for an
    in-tree-only build may just move the extracted source to the build
    directory).

    This is Builder's working area and it ususally doesn't mind you poking around
    or even deleting it from time to time. Things will (again) be set up as
    necessary.

  * `TARGET_PATH` will be used to build the proper `prefix` for the build. Some
    packages however dislike being installed into folders with spaces in them. If
    you encounter lines like `install 0644 /path/to/some : File not found` or
    similar, maybe your `TARGET_PATH` was `/path/to/some thing` and the packages
    `make install` chopped it off. Choose different `TARGET_PATH` and/or go
    complain to the package maintainers (not the build plan maintainers!).

    Another important aspect of the `TARGET_PATH` is, that it needs to be on a
    file system with `exec` permissions for most packages, and with symlink
    capability for some packages (e.g. libraries).

  * `PACKAGE_CACHE` is used to store the downloaded source-code packages, which
    are usually not architecture dependant. Since all downloads are constants and
    check-summed before each build, it may be a good idea to store these in a
    common folder.


## Build specific variables

  Builder specific variables are evaluated from the configuration variables in
  the following order:

  * `SOURCE` path to the extracted source code.
  * `TARGET` path where product will be installed (`--prefix`).
  * `BUILD`  work-space for temporary objects during the build process.
  * `LOG`    path to store standard and error output from different build steps.

  Each definition can reference only preceding ones, so you can express the
  `LOG` location relative to the `BUILD`, which is the default for `LOG_PATH`.


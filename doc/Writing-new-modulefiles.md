
# Modulefiles

  [Environment modules](https://modules.readthedocs.io/en/latest/index.html)
  are commonly used to select specific packages in an HPC environment. This
  approach is however not restricted to HPC systems and may as well be used on
  your own machine. It makes it possible to just `module load <something>` to
  select a specific installed version of a software.

  If `modules` are installed, the only required change to write your own
  modules is to have a `MODULESPATH` variable in your shell's environment.

     MODULESPATH=/path/to/your/modulefiles

  Builder supports populating such a directory, if the plan-file is accompanied
  by a `.module` template.

     build nest-simulator 2.20.1
     module load nest-simulator/2.20.1


# Writing new modulefiles

  After a package has succesfully been built, Builder checks if a `.module`
  file is present next to the plan file. If this is the case, the file is used
  as a template for installing a modulefile into the `MODULE_INSTALL_PATH`.
  Variables available to Builder are used to fill the template with
  build-specific information.

  Look at the [environment modules
  documentation](https://modules.readthedocs.io/en/latest/index.html) to learn
  how to write modulefiles in general. The following sections will detail
  different aspects of creating modules from Builder.

  A good starting point is the modulefile template provided in the
  documentation folder. You can copy it to a newly added package and modify
  parts where necessary.

## Package-specific setup

  Many packages require environment variables to be set up correctly. This is
  the prime use-case for the environment modules and many activation scripts
  can simply be translated. For example if a software requires sourcing a
  specific setup-file, the content of that file is usually what should go to a
  modulefile instead.

  Suppose there is a `some_vars.sh`, which is required by `some` package to be
  `source some_vars.sh` at the start. This file may contain lines like

    export SOME_INSTALL_PATH=/path/to/installation
    export PATH=/path/to/installation/bin:$PATH

  These translate to a modulefile

    #%Module1.0#
    setenv          SOME_INSTALL_DIR        /path/to/installation
    prepend-path    PATH                    /path/to/installation/bin

  Since the specific paths and other details of the build are known to Builder,
  many details need not be hard-coded and the available variables can
  automatically be substituted into the template by Builder. For a planfile
  `plans/some/1.0/default` Builder looks for a template named
  `plans/some/1.0/default.module` that could look like this:

    #%Module1.0#
    setenv          SOME_INSTALL_DIR        ${TARGET}
    prepend-path    PATH                    ${TARGET}/bin

  Look at existing `.module` files and the [Environment Modules
  Documentation](https://modules.readthedocs.io) for more information on what
  else to add to the templates.


## Run-time dependencies

  The modulefile can automatically pre-load run-time dependencies with `prereq`
  command, or `conflict` with other modules. See [command
  index](https://modules.readthedocs.io/en/latest/modulefile.html) for details.

  If a list contains more than one modulefile, then each member of the list
  acts as a Boolean `or` operation. Multiple `prereq` and `conflict` commands
  may be used to create a Boolean `and` operation.

  Usually only a single version of a package can be loaded at any time, so most
  templates contain at least a line excluding other versions of themselves.

     conflict ${PACKAGE}


## Libraries and Frameworks

  Providing a library as a module can provide *compile-time* dependencies and
  when loaded influences *builds* with that module loaded on the binary
  code-level.
  Other than tools with only a binary to be added to the `$PATH` (usually
  *run-time* dependencies), libraries and compile-time relevant frameworks
  require options set up for the used compilers, linkers and tool chain (build
  tools).

  Compile-time dependencies then may or may not become additional run-time
  dependencies for the built package. For example a compiler usually is not
  needed again by a tool during its run-time, on the other hand a library
  linked against needs to be available at run-time usually in that particular
  version used during compilation (See also "Run-time dependencies").

  To allow the build tools to find loaded modules, it is not feasible to encode
  all combinations of `-Dwith-somelib=/path/to/somelib/` for all tools and all
  their dependencies. Fortunately, compilers offer environment variables for
  exactly this purpose and those can be used similar to search `$PATH`, but for
  flags like `-i` and `-L`. Read about search paths and environment variables
  in your compiler documentation (e.g. for the GCC compiler
  [here](https://gcc.gnu.org/onlinedocs/cpp/Search-Path.html) and
  [here](https://gcc.gnu.org/onlinedocs/cpp/Environment-Variables.html)).
  Required compiler (`-i`) and linker (`-L`) include paths can be defined in a
  modulefile, so they become usable when the module is loaded. In a modulefile template:

  ```tcl
  prepend-path    CPATH            \$INSTALLDIR/include
  prepend-path    LIBRARY_PATH     \$INSTALLDIR/lib
  prepend-path    LD_LIBRARY_PATH  \$INSTALLDIR/lib
  ```

  Where

  * `CPATH` defines locations of include files that should be searched as if
    given with `-i` compiler flags (language independant, i.e. C and C++
    headers).
  * `LIBRARY_PATH` defines locations of libraries for static linking (i.e. that
    need to be available during compile-time) as if given with `-L` linker
    flags.
  * `LD_LIBRARY_PATH` defines locations for the dynamic linker to look for,
    when loading dynamic/shared libraries at run-time.

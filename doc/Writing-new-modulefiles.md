
# Module-files

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


# Writing new `modulefiles`

  After a package has succesfully been built, Builder checks if a `.module`
  file is present next to the plan file. If this is the case, the file is used
  as a template for installing a modulefile into the `MODULE_INSTALL_PATH`.
  Variables available to Builder are used to fill the template with
  build-specific information.

## Package-specific setup

  Many packages require environment variables to be set up correctly. This is
  the prime use-case for the environment modules and many activation scripts
  can simply be translated. For example if a software requires sourcing a
  specific setup-file, the content of that file is usually what should go to a
  module file instead.

  Suppose there is a `some_vars.sh`, which is required by `some` package to be
  `source some_vars.sh` at the start. This file may contain lines like

    export SOME_INSTALL_PATH=/path/to/installation
    export PATH=/path/to/installation/bin:$PATH

  These translate to a module file

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

  The modulefile can automatically pre-load runtime dependencies with `prereq`
  command, or `conflict` with other modules. See [command
  index](https://modules.readthedocs.io/en/latest/modulefile.html) for details.

  If a list contains more than one modulefile, then each member of the list
  acts as a Boolean `or` operation. Multiple prereq and conflict commands may be
  used to create a Boolean `and` operation.

  Usually only a single version of a package can be loaded at any time, so most
  templates contain at least a line excluding other versions of themselves.

     conflict ${PACKAGE}



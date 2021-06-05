

# Installing

As an alternative to installing Builder by manually creating a symlink (as
given in the [README](../README.md)), you can also use Builder to install
Builder itself.

First you would want to create a default config and check if everything is as
you want it to be:

    ./builder.sh configure
    vim ~/.buildrc      # chosse whichever editor you prefer

Then you can install builder by calling it from your local clone or download:

    ./build.sh Builder

or, if you work on the unstable development version:

    ./build.sh Builder unstable master

You can then use Builder by enabling it through the module system:

    module load Builder
    build --help


## Tough ones

Sometimes you find very few prerequisites on a system. This section describes
some more advanced setups that normally you would not need. Anyway, if you are
absolutely sure this is what you want, read on.


### Bootstrap Modules

Although not strictly necessary, the built packages become much more
comfortable to use with the use of environment modules. Just like any other
thing you want to build, this can also be set up by Builder.

The tricky part is, that you can not "module load Builder" or "module load
environment-modules", since former does not work without the latter and the
latter is obviously not built yet.

We can however call Builder directly and start building env modules

    ./build.sh environment-modules

This will build environment-modules as a normal package into your set install
path (see `~/.buildrc`). Alternative implementations like 'lmod' may be built
in a similar manner. Since many things depend on your choice here, you may want
to look into the install instructions and probably manually change things here
and there.

    less ~/install/environment-modules/4.7.1/default/share/doc/INSTALL.txt

To activate the environment-modules package obviously a "module load" is not
available. The packages usually provide a bash initialization script which
needs to be loaded during the initialization.  Put a line like the following
into your initialization scripts, for example when using bash add this to your
`~/.bashrc`:

    export MODULEPATH="your/MODULE/INSTALL/DIR${MODULEPATH:+:$MODULEPATH}"
    source ~/install/environment-modules/4.7.1/default/init/bash

This automatically sets the directory Builder places the module files in as the
default directory and initializes the module system. The appended
`${MODULEPATH:+:$MODULEPATH}` ensures that any previously set MODULEPATH is
still available.

After this you can install or load Builder and go on extending your deployment.


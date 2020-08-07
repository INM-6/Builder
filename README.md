
# 🏗 Builder

Collection of tools and scripts to install software on a system.

In contrast to usual packaging systems, the aim is to equally help users *and*
admins. Many aspects are inspired by
[Portage](https://wiki.gentoo.org/wiki/Project:Portage), which is used by the
[Gentoo](https://gentoo.org/) Linux distribution.


## Installation

To use Builder you just need to sym-link `build.sh` from a location that is in
your `$PATH`. You may have `~/bin` in your `$PATH` in which case you can do

    cd ~/bin
    ln -s path/to/builder/build.sh build

The only prerequisites are to have a system supporting sym-links with a proper
`/bin/bash` and `wget` installed.

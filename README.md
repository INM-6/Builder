
# 🏗 Builder

Collection of tools and scripts to install software on a system.

In contrast to usual packaging systems, the aim is to equally help users *and*
admins. Many aspects are inspired by
[Portage](https://wiki.gentoo.org/wiki/Project:Portage), which is used by the
[Gentoo](https://gentoo.org/) Linux distribution.

When using Builder, **please cite as stated** on the [releases page](https://github.com/INM-6/Builder/releases).

## Installation

To use Builder you just need to sym-link `build.sh` from a location that is in
your `$PATH`. You may have `~/bin` in your `$PATH` in which case you can do

    cd ~/bin
    ln -s path/to/builder/build.sh build

The only prerequisites are to have a system supporting sym-links with a proper
`bash`-compatible shell, `coreutils` and `wget` installed. Most systems should
have those by default, see [Trouble-shooting](doc/Trouble-shooting.md) anyway, if you
hit a strange error.

**Dependencies** (Linux/MacOS/Windows):

* `bash`-like shell
* `coreutils`
* `wget`

To set up the defaults for Builder run the configure command once:

    build configure

Then you can configure all relevant paths in `~/.buildrc`.  A more complete
description is in the [configuration details](doc/Configuration.md).

### Optional

To make best use of the installed packages, you likely also want to install a
package to load environment modules. This is however not used or required by
Builder.

Optional Dependencies:
* `environment-modules` or `lmod`


## Usage

You can install any software with Builder if a plan file is available. The
default location where Builder looks for plan files is configured as
`PLANFILE_PATH` in the [configuration](doc/Configuration.md). You will find
many files in the scheme `<package>/<version>/<variant>`, where the `<variant>`
uses `default` as its default value.

To install a package replace `<package>` and `<version>` with an available
build plan:

    build <package> [<version>] [<variant>] [<suffix>]

The parameter `<version>` is optional. It will default to installing the
highest version available.

If there are more variants available, you can optionally specify the
`<variant>` as third parameter.

If you want to add a suffix to the paths of certain `<variant>` of a `<version>`
of a `<package>`, you can optionally specify the `<suffix>` as a parameter.
This results in the files being copied to `<package>/<version>/<variant>_<suffix>.`

In any case, you can always get more details with

    build --help


## Contributing

PRs for new plan files or bug fixes are welcome. Some
documentation can be found in the [doc/ folder](doc/), where the [documentation
index](index.md) aims to give you a quick overview.


## License

 Builder is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Builder is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Builder.  If not, see <https://www.gnu.org/licenses/>.

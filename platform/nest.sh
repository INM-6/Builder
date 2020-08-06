#!/bin/bash
#
# This file is part of Builder.
#
# Builder is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Builder is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Builder.  If not, see <https://www.gnu.org/licenses/>.
#
set -euo pipefail

PACKAGE=nest-simulator
VERSION=${1:-2.18.0}
URL=https://github.com/nest/nest-simulator/archive/v${VERSION}.tar.gz

SOURCE=~/build/src/${PACKAGE}-${VERSION}
TARGET=~/install/${PACKAGE}/${VERSION}
BUILD=~/build/${PACKAGE}/${VERSION}
LOG=${BUILD}/logs

echo ">>> prepare source"
if [ ! -r "~/src/${PACKAGE}-${VERSION}.tar.gz" ]; then
	wget "$URL" -O "~/src/${PACKAGE}-${VERSION}.tar.gz"
fi
if [ ! -d $SOURCE ]; then
        mkdir -pv $(dirname $SOURCE)
        cd $(dirname $SOURCE)
        echo "extracting nest ${VERSION}"
        tar -xzf "~/src/${PACKAGE}-${VERSION}.tar.gz"
fi

echo ">>> prepare build"
if [ -d $BUILD ]; then
	read -p "sure you want to delete $BUILD? (ctrl-c for NO)"
	rm -vrf $BUILD
fi
mkdir -pv $BUILD
mkdir -pv $LOG

echo ">>> build"
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
cd $BUILD
set -x
module load cmake
if version_gt 2.16.0 $VERSION; then # version 2.14.0 and before requrie LTDL as hard dependency
	module load libtool
fi

cmake -Dwith-python=OFF -DCMAKE_INSTALL_PREFIX:PATH=$TARGET $SOURCE |& tee ${LOG}/cmake.log
make -j $(( $(nproc) / 4 )) |& tee ${LOG}/make.log
make install |& tee ${LOG}/make-install.log
awk 'BEGIN {f=3;x=0}; /^-------/{x=1;if (f>0) f--} f*x' ${LOG}/cmake.log >${TARGET}/ConfigurationSummary.txt

echo ">>> test"
make installcheck |& tee ${LOG}/make-installcheck.log
echo "installcheck passed." >>${TARGET}/ConfigurationSummary.txt
awk '/Testsuite Summary/{f=1} /Built target/{f=0} f;' ${LOG}/make-installcheck.log >>${TARGET}/ConfigurationSummary.txt

#!/bin/bash
set -euo pipefail

PACKAGE=libtool
VERSION=${1:-2.4.6}
URL=http://gnu.spinellicreations.com/libtool/${PACKAGE}-${VERSION}.tar.gz

SOURCE=~/build/src/${PACKAGE}-${VERSION}
TARGET=~/install/${PACKAGE}/${VERSION}
BUILD=~/build/${PACKAGE}/${VERSION}
LOG=${BUILD}/logs

set -x
echo ">>> prepare source"
if [ ! -r "$HOME/src/${PACKAGE}-${VERSION}.tar.gz" ]; then
	wget "$URL" -O "${HOME}/src/${PACKAGE}-${VERSION}.tar.gz"
fi
if [ ! -d $SOURCE ]; then
        mkdir -pv $(dirname $SOURCE)
        cd $(dirname $SOURCE)
        echo "extracting ${PACKAGE} ${VERSION}"
        tar -xzf "${HOME}/src/${PACKAGE}-${VERSION}.tar.gz"
fi

echo ">>> prepare build"
if [ -d $BUILD ]; then
	read -p "sure you want to delete $BUILD? (ctrl-c for NO)"
	rm -rf $BUILD
fi
mkdir -pv $BUILD
mkdir -pv $LOG

echo ">>> build"
cd $BUILD
set -x
${SOURCE}/configure --srcdir="${SOURCE}" --prefix="$TARGET" |& tee ${LOG}/configure.log
make -j $(( $(nproc) / 4 )) |& tee ${LOG}/make.log
make install |& tee ${LOG}/make-install.log

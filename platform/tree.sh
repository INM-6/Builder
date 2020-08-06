#!/bin/bash
set -euo pipefail

PACKAGE=tree
VERSION=${1:-1.8.0}
URL=ftp://mama.indstate.edu/linux/${PACKAGE}/${PACKAGE}-${VERSION}.tgz

SOURCE=~/build/src/${PACKAGE}-${VERSION}
TARGET=~/install/${PACKAGE}/${VERSION}
BUILD=~/build/${PACKAGE}/${VERSION}
LOG=${BUILD}/logs

set -x
echo ">>> prepare source"
if [ ! -r "$HOME/src/${PACKAGE}-${VERSION}.tgz" ]; then
	wget "$URL" -O "${HOME}/src/${PACKAGE}-${VERSION}.tgz"
fi
if [ ! -d $SOURCE ]; then
        mkdir -pv $(dirname $SOURCE)
        cd $(dirname $SOURCE)
        echo "extracting ${PACKAGE} ${VERSION}"
        tar -xzf "${HOME}/src/${PACKAGE}-${VERSION}.tgz"
fi

echo ">>> prepare build"
if [ -d $BUILD ]; then
	read -p "sure you want to delete $BUILD? (ctrl-c for NO)"
	rm -rf $BUILD
fi
mv -v "${SOURCE}" "${BUILD}"
mkdir -pv "${LOG}"

echo ">>> build"
cd "${BUILD}"
set -x
sed -i -e "s%prefix = .*%prefix = ${TARGET}%" Makefile
#${SOURCE}/configure --srcdir="${SOURCE}" --prefix="$TARGET" |& tee ${LOG}/configure.log
make -j $(( $(nproc) / 4 )) |& tee ${LOG}/make.log
make install |& tee ${LOG}/make-install.log

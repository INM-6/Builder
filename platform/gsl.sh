#!/bin/bash
set -euo pipefail
set -x

PACKAGE=gsl
VERSION=${1:-2.6}
SUFFIX=${2:-}
URL=ftp://ftp.gnu.org/gnu/${PACKAGE}/${PACKAGE}-${VERSION}.tar.gz

SOURCE=~/build/src/${PACKAGE}-${VERSION}
TARGET=~/install/${PACKAGE}/${VERSION}${SUFFIX}
BUILD=~/build/${PACKAGE}/${VERSION}
LOG=${BUILD}/logs

echo ">>> prepare source"
if [ ! -r "${HOME}/src/${PACKAGE}-${VERSION}.tar.gz" ]; then
	#wget "https://www.gnu.org/software/gsl/key/gsl_key.txt"
	wget -O "${HOME}/src/${PACKAGE}-${VERSION}.tar.gz.sig" "${URL}.sig"
	wget -O "${HOME}/src/${PACKAGE}-${VERSION}.tar.gz" "${URL}"
	gpg --import gsl_key.txt
	( cd ${HOME}/src/;
	  gpg --verify gsl-${VERSION}.tar.gz.sig )
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
	rm -vrf $BUILD
fi
mkdir -pv $BUILD
mkdir -pv $LOG

echo ">>> build"
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }
cd $BUILD
set -x

$SOURCE/configure --prefix=$TARGET --srcdir=$SOURCE |& tee ${LOG}/configure.log
make -j $(( $(nproc) / 4 )) |& tee ${LOG}/make.log
make install |& tee ${LOG}/make-install.log

awk 'BEGIN {f=2;x=0}; /^-------/{x=1;if (f>0) f--} f*x' ${LOG}/make-install.log  >${TARGET}/ConfigurationSummary.txt


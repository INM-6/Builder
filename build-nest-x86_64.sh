set -euo pipefail

module load cmake
#VERSION=master
#SOURCE=~/sdvlp/nest-simulator

VERSION=${1:-2.18.0}
SOURCE=~/build/src/nest-simulator-${VERSION}
TARGET=~/install/nest-simulator/${VERSION}
BUILD=~/build/nest-simulator/${VERSION}
LOG=${BUILD}/logs

echo ">>> prepare source"
if [ ! -d $SOURCE ]; then
        mkdir -pv $(dirname $SOURCE)
        cd $(dirname $SOURCE)
        echo "extracting nest ${VERSION}"
        tar -xzf ~/src/nest-simulator-${VERSION}.tar.gz
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
cmake -Dwith-python=OFF -DCMAKE_INSTALL_PREFIX:PATH=$TARGET $SOURCE |& tee ${LOG}/cmake.log
make -j $(( $(nproc) / 4 )) |& tee ${LOG}/make.log
make install |& tee ${LOG}/make-install.log
awk 'BEGIN {f=3;x=0}; /^-------/{x=1;if (f>0) f--} f*x' ${LOG}/cmake.log >${TARGET}/ConfigurationSummary.txt
make installcheck |& tee ${LOG}/make-installcheck.log
echo "installcheck passed." >>${TARGET}/ConfigurationSummary.txt
awk '/Testsuite Summary/{f=1} /Built target/{f=0} f;' ${LOG}/make-installcheck.log >>${TARGET}/ConfigurationSummary.txt

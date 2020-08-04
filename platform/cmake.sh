set -euo pipefail

VERSION=3.18.0
tar -xzf ~/src/cmake-${VERSION}.tar.gz
cd cmake-${VERSION}
./bootstrap --prefix=~/install/cmake/${VERSION}
make
make install

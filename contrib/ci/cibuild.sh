#!/bin/sh
set -e

echo "C compiler: $CC"
echo "C++ compiler: $CXX"
set -x

#
# This script is supposed to run inside the RHD2000 Docker container
# on the CI system.
#

$CC --version

# configure build with all flags enabled
mkdir build && cd build
cmake -DMAINTAINER=OFF \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    ..

# Build, Test & Install
make -j4
DESTDIR=/tmp/install_root/ make install
cd ..
rm -rf build/

#
# Build Debian package
#

git_commit=$(git log --pretty="format:%h" -n1)
git_current_tag=$(git describe --tags 2> /dev/null || echo "v1.5.2")
git_commit_no=$(git rev-list --count HEAD)
upstream_version=$(echo "${git_current_tag}" | sed 's/^v\(.\+\)$/\1/;s/[-]/./g')
upstream_version="$upstream_version+git$git_commit_no"

mv contrib/debian .
dch --distribution "UNRELEASED"	--newversion="${upstream_version}" -b \
    "New automated build from: ${upstream_version} - ${git_commit}"

dpkg-buildpackage
mv ../*.deb .

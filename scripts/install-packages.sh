#!/usr/bin/env sh

# Installs the packages needed to build QuartzCore and its dependency stack on
# a Debian or Ubuntu machine.  Reads CC and RUNTIME_VERSION for the parts that
# depend on the toolchain.  Pass "display" to add what a run against a real
# display needs: the X development libraries libs-back builds its server layer
# against, and Xvfb to provide the display itself.

set -ex

PACKAGES="pkg-config
libgnutls28-dev
libffi-dev
libicu-dev
libxml2-dev
libxslt1-dev
libssl-dev
libavahi-client-dev
zlib1g-dev
gnutls-bin
libcurl4-gnutls-dev
libgmp-dev
libcairo2-dev
libfreetype-dev
libfontconfig-dev
libx11-dev
libxrender-dev
liblcms2-dev
libjpeg-dev
libtiff-dev
libpng-dev
libgl1-mesa-dev
libglu1-mesa-dev"

# libobjc2 and libdispatch are built when compiling with clang.
case "${CC:-}" in
  *clang*)
    PACKAGES="$PACKAGES
libpthread-workqueue-dev"
    ;;
esac

if [ "${1:-}" = "display" ]; then
    PACKAGES="$PACKAGES
libxt-dev
libxmu-dev
libxft-dev
libxrandr-dev
libxfixes-dev
libxcursor-dev
xvfb"
fi

sudo apt-get -q -y update
sudo apt-get -q -y install $PACKAGES

# The gnustep-2.0 runtime needs ld.gold or lld.
if [ "${RUNTIME_VERSION:-}" = "gnustep-2.0" ]; then
    sudo update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.gold" 10
fi

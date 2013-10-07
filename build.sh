#!/bin/sh

set -e

# Speed up builds
/etc/init.d/apt-cacher-ng start
export http_proxy=http://localhost:3142/

# Set variables
KALI_VERSION="${VERSION:-daily}"
TARGET_DIR=$(dirname $0)/images/kali-$KALI_VERSION
KALI_ARCH="i386"
IMAGE_NAME="binary.hybrid.iso"
KALI_CONFIG_OPTS="-- --proposed-updates"
KERNEL=`apt-cache search linux-image | grep linux-image-$(uname -r) | grep -v dbg | awk '{print $1}' | sed 's/-686-pae//'`

# Set sane PATH (cron seems to lack /sbin/ dirs)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Ensure we have proper version installed
ver_live_build=$(dpkg-query -f '${Version}' -W live-build)
if dpkg --compare-versions "$ver_live_build" lt 3.0~b6; then
	echo "You need live-build (>= 3.0~b6), you have $ver_live_build" >&2
	exit 1
fi

cd $(dirname $0)
mkdir -p $TARGET_DIR

# Build
rm -vfr chroot/binary
lb clean --purge >prepare.log 2>&1
lb config -a $KALI_ARCH --linux-packages $KERNEL $KALI_CONFIG_OPTS >>prepare.log 2>&1
lb build

if [ $? -ne 0 ] || [ ! -e $IMAGE_NAME ]; then
	echo "Build of $KALI_ARCH live image failed" >&2
	exit 1
fi

[ -d images ] || mkdir images
IMAGE_EXT="${IMAGE_EXT:-${IMAGE_NAME##*.}}"
mv $IMAGE_NAME $TARGET_DIR/kali-$KALI_VERSION-$KALI_ARCH.$IMAGE_EXT
mv binary.log $TARGET_DIR/kali-$KALI_VERSION-$KALI_ARCH.log

if [ -x ../bin/update-checksums ]; then
	../bin/update-checksums $TARGET_DIR
fi

#!/bin/sh

set -e

# Speed up builds
# /etc/init.d/apt-cacher-ng restart

# Hack because apt-cacher doesn't seem to like the tmpfs log directory for some reason
killall -9 apt-cacher-ng
apt-cacher-ng || true

# export http_proxy=http://127.0.0.1:3142/

# Set mirror options
MIRROR_OPTIONS=\
'--apt-http-proxy http://127.0.0.1:3142 '
#'--mirror-bootstrap http://127.0.0.1:3142/archive.kali.org/kali '\
#'--mirror-debian-installer http://127.0.0.1:3142/archive.kali.org/kali '\
#'--mirror-chroot http://127.0.0.1:3142/archive.kali.org/kali '\
#'--mirror-chroot-security http://127.0.0.1:3142/archive.kali.org/kali-security '\
#'--mirror-binary http://127.0.0.1:3142/http.kali.org/kali '\
#'--mirror-binary-security http://127.0.0.1:3142/security.kali.org/kali-security '

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
lb clean > prepare.log 2>&1
lb config $MIRROR_OPTIONS -a $KALI_ARCH --linux-packages $KERNEL $KALI_CONFIG_OPTS >> prepare.log 2>&1
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

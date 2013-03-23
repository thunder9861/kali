#!/bin/bash

bin=./config/includes.chroot/root/bin/
source=./chroot/
destination=./config/includes.chroot/

# Create an aufs layer
$bin/aufs $source $destination

# Chroot into the system
$bin/xchroot $source

# Unmount the aufs layer
umount -v $source || umount -v -lf $source

# Cleanup
rm -rfv $destination/.wh..wh.aufs
rm -rfv $destination/.wh..wh.orph
rm -rfv $destination/.wh..wh.plnk

#!/bin/bash

target=""

# Determine the argument representing the filesystem ("/")
for opt in $@
do
   case "${opt}" in
   --device)
      ;;
   --target=*)
      target=${opt#*=}
      ;;
   *)
      arg=$opt
      ;;
   esac
done

case "$target" in
   partmap)
      echo "$GRUB_PROBE_PARTMAP"
      ;;
   drive)
      echo "$GRUB_PROBE_DRIVE"
      ;;
   device)
      echo "$GRUB_PROBE_DEVICE"
      ;;
   fs)
      echo "$GRUB_PROBE_FS"
      ;;
   fs_uuid)
      echo "$GRUB_PROBE_FS_UUID"
      ;;
   *)
      echo
      ;;
esac


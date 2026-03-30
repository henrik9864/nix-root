# Script that calculates partition sizes and prints the image layout
{ pkgs, cfg, kernel, initrd, rootfs, dtbFile }:

let
  kernelImageFile = cfg.kernel.imageFile;
  rootDevice      = cfg.output.rootDevice;

  bootloaderReserved = cfg.image.bootloaderReserved;
  bootSizeMin        = cfg.image.bootSizeMin;
  rootfsSizeMin      = cfg.image.rootfsSizeMin;
  bootPadding        = cfg.image.bootPadding;
  rootfsPadding      = cfg.image.rootfsPadding;
in

pkgs.writeShellScript "calc-sizes.sh" ''
  size_mib() {
    local bytes
    bytes=$(du -sb "$1" | cut -f1)
    echo $(( (bytes + 1048575) / 1048576 ))
  }

  BOOT_CONTENT_SIZE=0
  BOOT_CONTENT_SIZE=$((BOOT_CONTENT_SIZE + $(size_mib ${kernel}/${kernelImageFile})))
  BOOT_CONTENT_SIZE=$((BOOT_CONTENT_SIZE + $(size_mib ${dtbFile})))
  BOOT_CONTENT_SIZE=$((BOOT_CONTENT_SIZE + $(size_mib ${initrd}/initrd)))

  ROOTFS_CONTENT_SIZE=$(size_mib ${rootfs})

  BOOT_SIZE=$((BOOT_CONTENT_SIZE + ${toString bootPadding}))
  if [ "$BOOT_SIZE" -lt "${toString bootSizeMin}" ]; then
    BOOT_SIZE=${toString bootSizeMin}
  fi

  ROOTFS_SIZE=$((ROOTFS_CONTENT_SIZE + ${toString rootfsPadding}))
  if [ "$ROOTFS_SIZE" -lt "${toString rootfsSizeMin}" ]; then
    ROOTFS_SIZE=${toString rootfsSizeMin}
  fi

  BOOT_START=${toString bootloaderReserved}
  ROOTFS_START=$((BOOT_START + BOOT_SIZE))
  TOTAL_SIZE=$((ROOTFS_START + ROOTFS_SIZE))

  echo ":: Image layout (${cfg.output.target}) ::"
  echo "  Target: ${cfg.output.target}"
  echo "  Root device: ${rootDevice}"
  echo "  Boot content:  ''${BOOT_CONTENT_SIZE} MiB"
  echo "  Boot partition: ''${BOOT_SIZE} MiB (min ${toString bootSizeMin}, padding ${toString bootPadding})"
  echo "  Rootfs content: ''${ROOTFS_CONTENT_SIZE} MiB"
  echo "  Rootfs partition: ''${ROOTFS_SIZE} MiB (min ${toString rootfsSizeMin}, padding ${toString rootfsPadding})"
  echo "  Total image: ''${TOTAL_SIZE} MiB"

  export BOOT_SIZE ROOTFS_SIZE BOOT_START ROOTFS_START TOTAL_SIZE
''
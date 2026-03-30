# Script that creates the raw image, flashes the bootloader, and writes the partition table
{ pkgs, cfg, bootloader, imageName }:

let
  bootloaderFlashCmds = builtins.concatStringsSep "\n" (
    map (f: ''
      dd if=${bootloader}/${f.file} of=$IMG bs=512 seek=${toString f.offset} conv=notrunc
    '') cfg.bootloader.files
  );
in

pkgs.writeShellScript "create-image.sh" ''
  mkdir -p $out
  IMG=$out/${imageName}

  dd if=/dev/zero of=$IMG bs=1M count=$TOTAL_SIZE

  # Bootloader
  ${bootloaderFlashCmds}

  # Partition table
  BOOT_START_S=$((BOOT_START * 2048))
  BOOT_SIZE_S=$((BOOT_SIZE * 2048))
  ROOTFS_START_S=$((ROOTFS_START * 2048))

  sfdisk $IMG <<EOF
label: dos
start=''${BOOT_START_S},   size=''${BOOT_SIZE_S}, type=c, bootable
start=''${ROOTFS_START_S}, type=83
EOF

  export IMG
''
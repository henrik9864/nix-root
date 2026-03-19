{ pkgs, cfg, uboot, kernel, initrd, rootfs }:

let
  dtbName     = cfg.board.dtb;
  rootDevice  = cfg.output.rootDevice;
  imageSuffix = cfg.output.imageSuffix;
  imageName   = "${cfg.board.name}${imageSuffix}.img";

  ubootReserved = cfg.image.ubootReserved;
  bootSizeMin   = cfg.image.bootSizeMin;
  rootfsSizeMin = cfg.image.rootfsSizeMin;
  bootPadding   = cfg.image.bootPadding;
  rootfsPadding = cfg.image.rootfsPadding;

  consoleArgs =
    "console=${cfg.serial.console} console=tty1"
    + (if cfg.serial.extraArgs != "" then " ${cfg.serial.extraArgs}" else "");
in

pkgs.stdenv.mkDerivation {
  name = "${cfg.board.name}${imageSuffix}-image";

  nativeBuildInputs = with pkgs; [
    dosfstools
    mtools
    util-linux
    e2fsprogs
    coreutils
  ];

  buildCommand = ''
    # ── Calculate sizes ────────────────────────────────
    # Helper: size of a path in MiB, rounded up
    size_mib() {
      local bytes
      bytes=$(du -sb "$1" | cut -f1)
      echo $(( (bytes + 1048575) / 1048576 ))
    }

    # Boot contents: kernel Image + DTB + initrd
    BOOT_CONTENT_SIZE=0
    BOOT_CONTENT_SIZE=$((BOOT_CONTENT_SIZE + $(size_mib ${kernel}/Image)))
    BOOT_CONTENT_SIZE=$((BOOT_CONTENT_SIZE + $(size_mib ${kernel}/dtbs/rockchip/${dtbName})))
    BOOT_CONTENT_SIZE=$((BOOT_CONTENT_SIZE + $(size_mib ${initrd}/initrd)))

    # Rootfs contents
    ROOTFS_CONTENT_SIZE=$(size_mib ${rootfs})

    # Apply minimums and padding
    BOOT_SIZE=$((BOOT_CONTENT_SIZE + ${toString bootPadding}))
    if [ "$BOOT_SIZE" -lt "${toString bootSizeMin}" ]; then
      BOOT_SIZE=${toString bootSizeMin}
    fi

    ROOTFS_SIZE=$((ROOTFS_CONTENT_SIZE + ${toString rootfsPadding}))
    if [ "$ROOTFS_SIZE" -lt "${toString rootfsSizeMin}" ]; then
      ROOTFS_SIZE=${toString rootfsSizeMin}
    fi

    BOOT_START=${toString ubootReserved}
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

    # ── Create image ───────────────────────────────────
    mkdir -p $out
    IMG=$out/${imageName}

    dd if=/dev/zero of=$IMG bs=1M count=$TOTAL_SIZE

    # U-Boot
    dd if=${uboot}/idbloader.img of=$IMG bs=512 seek=${toString cfg.uboot.idbloaderOffset} conv=notrunc
    dd if=${uboot}/u-boot.itb    of=$IMG bs=512 seek=${toString cfg.uboot.itbOffset}       conv=notrunc

    # Partition table (sector math)
    BOOT_START_S=$((BOOT_START * 2048))
    BOOT_SIZE_S=$((BOOT_SIZE * 2048))
    ROOTFS_START_S=$((ROOTFS_START * 2048))

    sfdisk $IMG <<EOF
label: dos
start=''${BOOT_START_S},   size=''${BOOT_SIZE_S}, type=c, bootable
start=''${ROOTFS_START_S}, type=83
EOF

    # Boot partition (FAT32)
    dd if=/dev/zero of=boot.fat bs=1M count=$BOOT_SIZE
    mkfs.fat -F 32 -n BOOT boot.fat

    mcopy -i boot.fat ${kernel}/Image                    ::Image
    mcopy -i boot.fat ${kernel}/dtbs/rockchip/${dtbName} ::${dtbName}
    mcopy -i boot.fat ${initrd}/initrd                   ::initrd

    cat > extlinux.conf << CONF
TIMEOUT 10
DEFAULT ${cfg.board.name}

LABEL ${cfg.board.name}
  KERNEL  /Image
  INITRD  /initrd
  FDT     /${dtbName}
  APPEND  ${consoleArgs} root=${rootDevice} rootfstype=ext4 rootwait rw init=/init
CONF

    mmd   -i boot.fat ::/extlinux
    mcopy -i boot.fat extlinux.conf ::/extlinux/extlinux.conf
    dd if=boot.fat of=$IMG bs=1M seek=$BOOT_START conv=notrunc

    # Root partition (ext4)
    dd if=/dev/zero of=rootfs.ext4 bs=1M count=$ROOTFS_SIZE
    mkfs.ext4 -L rootfs -d ${rootfs} rootfs.ext4
    dd if=rootfs.ext4 of=$IMG bs=1M seek=$ROOTFS_START conv=notrunc
  '';
}
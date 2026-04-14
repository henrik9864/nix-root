# Script that creates and populates the FAT32 boot partition
{
  pkgs,
  cfg,
  kernel,
  initrd,
  dtbName,
  dtbFile,
}: let
  kernelImageFile = cfg.kernel.imageFile;
  rootDevice = cfg.output.rootDevice;

  consoleArgs =
    "console=${cfg.serial.console} console=tty1"
    + (
      if cfg.serial.extraArgs != ""
      then " ${cfg.serial.extraArgs}"
      else ""
    );
in
  pkgs.writeShellScript "boot-partition.sh" ''
      dd if=/dev/zero of=boot.fat bs=1M count=$BOOT_SIZE
      mkfs.fat -F 32 -n BOOT boot.fat

      mcopy -i boot.fat ${kernel}/${kernelImageFile} ::${kernelImageFile}
      mcopy -i boot.fat ${dtbFile}                   ::${dtbName}
      mcopy -i boot.fat ${initrd}/initrd             ::initrd

      cat > extlinux.conf << CONF
    TIMEOUT 10
    DEFAULT ${cfg.board.name}

    LABEL ${cfg.board.name}
      KERNEL  /${kernelImageFile}
      INITRD  /initrd
      FDT     /${dtbName}
      APPEND  ${consoleArgs} root=${rootDevice} rootfstype=ext4 rootwait rw init=/init
    CONF

      mmd   -i boot.fat ::/extlinux
      mcopy -i boot.fat extlinux.conf ::/extlinux/extlinux.conf
      dd if=boot.fat of=$IMG bs=1M seek=$BOOT_START conv=notrunc
  ''

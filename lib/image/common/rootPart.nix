# Script that creates and populates the ext4 root partition
{
  pkgs,
  rootfs,
}:
pkgs.writeShellScript "root-partition.sh" ''
  dd if=/dev/zero of=rootfs.ext4 bs=1M count=$ROOTFS_SIZE
  mkfs.ext4 -L rootfs -d ${rootfs} rootfs.ext4
  dd if=rootfs.ext4 of=$IMG bs=1M seek=$ROOTFS_START conv=notrunc
''

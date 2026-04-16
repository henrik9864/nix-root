# Shell script: builds a JFFS2 image from the rootfs store path
# and writes it to $out/rootfs.jffs2.
{
  pkgs,
  rootfs,
  eraseBlockSize, # bytes — must match board NAND erase block size
}:
pkgs.writeShellScript "jffs2-rootfs.sh" ''
  mkfs.jffs2 \
    --root=${rootfs} \
    --output=$out/rootfs.jffs2 \
    --eraseblock=${toString eraseBlockSize} \
    --little-endian \
    --squash
''

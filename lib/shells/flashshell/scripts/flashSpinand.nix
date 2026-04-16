{
  pkgs,
  miniloaderBin,
  scriptName,
}:
pkgs.writeShellScript scriptName ''
  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

  echo "[1/6] Loading miniloader to RAM..."
  upgrade_tool db "$SCRIPT_DIR/firmware/${miniloaderBin}"

  echo "[2/6] Writing IDB loader to NAND..."
  upgrade_tool di -loader "$SCRIPT_DIR/firmware/${miniloaderBin}"

  echo "[3/6] Writing partition table..."
  upgrade_tool di -p "$SCRIPT_DIR/images/parameter.txt"

  echo "[4/6] Writing U-Boot..."
  upgrade_tool di -uboot "$SCRIPT_DIR/images/uboot.img"

  echo "[5/6] Writing boot image..."
  upgrade_tool di -boot "$SCRIPT_DIR/images/boot.img"

  echo "[6/6] Writing rootfs..."
  upgrade_tool di -userdata "$SCRIPT_DIR/images/rootfs.jffs2"

  upgrade_tool rd
  echo "Done."
''


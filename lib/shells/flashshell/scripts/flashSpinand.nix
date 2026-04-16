{
  pkgs,
  miniloaderBin,
  scriptName,
  ubootSector,
  bootSector,
  userdataSector,
}:
pkgs.writeShellScript scriptName ''
  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

  echo "[1/5] Loading miniloader to RAM..."
  upgrade_tool db "$SCRIPT_DIR/firmware/${miniloaderBin}"

  echo "[2/5] Writing IDB loader to NAND at sector 0..."
  upgrade_tool wl 0 "$SCRIPT_DIR/firmware/${miniloaderBin}"

  echo "[3/5] Writing U-Boot (sector ${toString ubootSector})..."
  upgrade_tool wl ${toString ubootSector} "$SCRIPT_DIR/images/uboot.img"

  echo "[4/5] Writing boot image (sector ${toString bootSector})..."
  upgrade_tool wl ${toString bootSector} "$SCRIPT_DIR/images/boot.img"

  echo "[5/5] Writing rootfs (sector ${toString userdataSector})..."
  upgrade_tool wl ${toString userdataSector} "$SCRIPT_DIR/images/rootfs.jffs2"

  upgrade_tool rd
  echo "Done."
''


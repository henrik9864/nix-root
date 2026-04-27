{
  pkgs,
  miniloaderBin,
  scriptName,
}:
pkgs.writeShellScript scriptName ''
  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

  echo "[1/4] Loading miniloader to RAM..."
  upgrade_tool db "$SCRIPT_DIR/firmware/${miniloaderBin}"

  echo "[2/4] Writing IDB loader (SPL/DDR init) at sector 0x200..."
  upgrade_tool wl 0x800 "$SCRIPT_DIR/firmware/idblock.img"

  echo "[3/4] Writing U-Boot at sector 0x400..."
  upgrade_tool wl 0x4000 "$SCRIPT_DIR/firmware/uboot.img"

  upgrade_tool rd
  echo "Done."
''


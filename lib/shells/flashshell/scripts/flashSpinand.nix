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
	
  echo "[2/6] Writing parameter.txt at sector 0x0..."
  upgrade_tool wl 0x0 "$SCRIPT_DIR/images/parameter.txt"

  echo "[3/6] Writing U-Boot at sector 0x4000..."
  upgrade_tool wl 0x4000 "$SCRIPT_DIR/firmware/uboot.img"

  echo "[4/6] Writing kernel.img at sector 0x8000..."
  upgrade_tool wl 0x8000 "$SCRIPT_DIR/images/kernel.img"
	
  echo "[5/6] Writing devicetree.dtb at sector 0x10000..."
  upgrade_tool wl 0x10000 "$SCRIPT_DIR/images/devicetree.dtb"

  echo "[6/6] Writing initrd.img at sector 0x11000..."
  upgrade_tool wl 0x11000 "$SCRIPT_DIR/images/initrd.img"

  upgrade_tool rd
  echo "Done."
''

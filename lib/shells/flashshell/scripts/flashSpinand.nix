{
  pkgs,
  lib,
  partitions,
  miniloaderBin,
  scriptName,
}:
let
  mibToSectors = mib: mib * 2048;
  toHex = n: "0x${lib.toHexString n}";

  flashParts = builtins.filter (p: p.flashFile != null) partitions;
  total = builtins.length flashParts + 2; # miniloader + parameter.txt

  writeCmds = lib.imap1 (i: p: ''
    echo "[${toString (i + 2)}/${toString total}] Writing ${p.name} at sector ${toHex (mibToSectors p.offsetMiB)}..."
    upgrade_tool wl ${toHex (mibToSectors p.offsetMiB)} "$SCRIPT_DIR/${p.flashFile}"'') flashParts;
in
  pkgs.writeShellScript scriptName ''
    #!/usr/bin/env bash
    set -euo pipefail
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

    echo "[1/${toString total}] Loading miniloader to RAM..."
    upgrade_tool db "$SCRIPT_DIR/firmware/${miniloaderBin}"

    echo "[2/${toString total}] Writing parameter.txt at sector 0x0..."
    upgrade_tool wl 0x0 "$SCRIPT_DIR/images/parameter.txt"

    ${builtins.concatStringsSep "\n\n" writeCmds}

    upgrade_tool rd
    echo "Done."
  ''

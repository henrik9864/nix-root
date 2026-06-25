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
  fixedStepCount = 4; # erase + miniloader + parameter.txt + idblock
  total = builtins.length flashParts + fixedStepCount;

  writeCmds = lib.imap1 (i: p: ''
    echo "[${toString (i + fixedStepCount)}/${toString total}] Writing ${p.name} at sector ${toHex (mibToSectors p.offsetMiB)}..."
    _f="$SCRIPT_DIR/${p.flashFile}"
    _sectors=$(( ($(stat -c %s "$_f") + 511) / 512 ))
    upgrade_tool wl ${toHex (mibToSectors p.offsetMiB)} $_sectors "$_f"'') flashParts;
in
  pkgs.writeShellScript scriptName ''
    #!/usr/bin/env bash
    set -euo pipefail
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

    echo "[1/${toString total}] Erasing flash..."
    upgrade_tool ef "$SCRIPT_DIR/firmware/${miniloaderBin}"

    sleep 2

    echo "[2/${toString total}] Loading miniloader to RAM..."
    upgrade_tool db "$SCRIPT_DIR/firmware/${miniloaderBin}"

    sleep 1

    echo "[3/${toString total}] Writing parameter.txt at sector 0x0..."
    upgrade_tool wl 0x0 "$SCRIPT_DIR/images/parameter.txt"

    echo "[4/${toString total}] Writing loader (idblock) at sector 0x100..."
    upgrade_tool wl 0x100 "$SCRIPT_DIR/firmware/idblock.img"

    ${builtins.concatStringsSep "\n\n" writeCmds}

    upgrade_tool rd
    echo "Done."
  ''

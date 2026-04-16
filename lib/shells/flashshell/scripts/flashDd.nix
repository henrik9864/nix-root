{
  pkgs,
  bootloaderFiles,
  imagePath,
  scriptName,
}:
pkgs.writeShellScript scriptName (
  ''
    #!/usr/bin/env bash
    set -euo pipefail
    DEV="''${1:-}"
    if [ -z "$DEV" ]; then
      echo "Usage: ${scriptName} <device>"
      echo "Example: sudo ${scriptName} /dev/sdX"
      exit 1
    fi
    echo "Flashing ${imagePath} to $DEV..."
  ''
  + builtins.concatStringsSep "\n" (
    map (f: "  dd if=firmware/${f.file} of=\"$DEV\" bs=512 seek=${toString f.offset} conv=notrunc")
    bootloaderFiles
  )
  + ''

    dd if="${imagePath}" of="$DEV" bs=4M conv=fsync status=progress
    sync
    echo "Done."
  ''
)

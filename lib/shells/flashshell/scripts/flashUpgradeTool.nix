{
  pkgs,
  miniloaderBin,
  imagePath,
  scriptName,
}:
pkgs.writeShellScript scriptName ''
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Flashing ${imagePath} via upgrade_tool..."
  upgrade_tool db firmware/${miniloaderBin}
  upgrade_tool wl 0 "${imagePath}"
  upgrade_tool rd
  echo "Done."
''

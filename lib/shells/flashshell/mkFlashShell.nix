{targets}: let
  anyTarget = (builtins.attrValues targets) |> builtins.head;
  cfg = anyTarget.cfg;
  nativePkgs = cfg._nativePkgs;
  lib = nativePkgs.lib;
  bootloader = cfg.bootloader.package;
  method = cfg.flash.method;
  miniloader = cfg.flash.miniloader;
  kernel = anyTarget.kernel;
  copyBootloaderCmds = cfg.bootloader.files
    |> map (f: ''
      cp ${bootloader}/${f.file} "$FLASH_DIR/firmware/${f.file}"
    '')
    |> builtins.concatStringsSep "\n";
  copyMiniloaderCmd = lib.optionalString (miniloader != null) ''
    cp ${miniloader}/*.bin "$FLASH_DIR/firmware/"
  '';
  copyImageCmds = targets
    |> builtins.mapAttrs (_: project: ''
        cp -r ${project.image}/* "$FLASH_DIR/images/"
      '')
    |> builtins.attrValues
    |> builtins.concatStringsSep "\n";

  # Copy kernel debug artifacts
  copyDebugCmds = ''
    echo "Copying kernel debug artifacts..."
    if [ -f "${kernel}/vmlinux" ]; then
      cp "${kernel}/vmlinux" "$FLASH_DIR/debug/vmlinux" 2>/dev/null || true
    fi
    find ${kernel} -name "vmlinux" -exec cp {} "$FLASH_DIR/debug/" \; 2>/dev/null || true
    find ${kernel} -name ".config" -exec cp {} "$FLASH_DIR/debug/kernel.config" \; 2>/dev/null || true
    find ${kernel} -name "System.map" -exec cp {} "$FLASH_DIR/debug/" \; 2>/dev/null || true
    find ${kernel} -name "Module.symvers" -exec cp {} "$FLASH_DIR/debug/" \; 2>/dev/null || true
    # Also list everything in the kernel output for inspection
    ls -la ${kernel} > "$FLASH_DIR/debug/kernel-output-listing.txt" 2>/dev/null || true
    find ${kernel} -maxdepth 3 -type f > "$FLASH_DIR/debug/kernel-files.txt" 2>/dev/null || true
  '';

  miniloaderBin =
    if miniloader != null
    then "${miniloader}" |> builtins.readDir |> builtins.attrNames |> builtins.head
    else "miniloader.bin";
  mkFlashScript = targetName: project: let
    scriptName = "flash-${targetName}.sh";
    imageName = "${project.image}" |> builtins.readDir |> builtins.attrNames |> builtins.head;
    imagePath = "images/${imageName}";
    method = if targetName == "spinand" then "spinand" else cfg.flash.method;
  in
    if method == "spinand" then
      import ./scripts/flashSpinand.nix {
        pkgs = nativePkgs;
        inherit miniloaderBin scriptName;
      }
    else if method == "dd" then
      import ./scripts/flashDd.nix {
        pkgs = nativePkgs;
        bootloaderFiles = cfg.bootloader.files;
        inherit imagePath scriptName;
      }
    else
      throw "Unknown flash method: ${method}. Supported methods: spinand, dd";
  flashScripts = builtins.mapAttrs mkFlashScript targets;
  copyFlashScriptCmds = flashScripts
    |> builtins.mapAttrs (targetName: script: ''
        cp ${script} "$FLASH_DIR/flash-${targetName}.sh"
        chmod +x "$FLASH_DIR/flash-${targetName}.sh"
      '')
    |> builtins.attrValues
    |> builtins.concatStringsSep "\n";
  hasSpinand = builtins.hasAttr "spinand" targets;
  methodPackages = (if hasSpinand then [nativePkgs.upgrade-tool] else [])
    ++ cfg.flash.extraPackages
    ++ [nativePkgs.usbutils nativePkgs.util-linux nativePkgs.binutils];
in
  nativePkgs.mkShell {
    name = "${cfg.board.name}-flash";
    packages = methodPackages;
    shellHook = ''
      FLASH_DIR=$(mktemp -d "/tmp/${cfg.board.name}-flash-XXXXXX")
      export FLASH_DIR
      mkdir -p "$FLASH_DIR/images" "$FLASH_DIR/firmware" "$FLASH_DIR/debug"
      ${copyBootloaderCmds}
      ${copyMiniloaderCmd}
      ${copyImageCmds}
      ${copyFlashScriptCmds}
      ${copyDebugCmds}
      cleanup() {
        rm -rf "$FLASH_DIR"
        echo "Cleaned up flash dir: $FLASH_DIR"
      }
      trap cleanup EXIT
      echo ""
      echo "══════════════════════════════════════════════════════"
      echo "  ${cfg.board.name} — Flash Shell (${method})"
      echo "══════════════════════════════════════════════════════"
      echo ""
      echo "Flash dir: $FLASH_DIR"
      echo ""
      echo "Available flash scripts:"
      for s in "$FLASH_DIR"/flash-*.sh; do
        echo "  sudo $(basename $s)"
      done
      echo ""
      echo "Debug artifacts:"
      ls "$FLASH_DIR/debug/" 2>/dev/null
      echo ""
      cd "$FLASH_DIR"
    '';
  }

{targets}: let
  # All targets share the same board config, grab it from the first
  anyTarget = builtins.head (builtins.attrValues targets);
  cfg = anyTarget.cfg;
  nativePkgs = cfg._nativePkgs;
  lib = nativePkgs.lib;

  bootloader = cfg.bootloader.package;
  method = cfg.flash.method;
  miniloader = cfg.flash.miniloader;

  # ── Copy commands ────────────────────────────────────────────────

  copyBootloaderCmds = builtins.concatStringsSep "\n" (
    map (f: ''
      cp ${bootloader}/${f.file} "$FLASH_DIR/firmware/${f.file}"
    '')
    cfg.bootloader.files
  );

  copyMiniloaderCmd = lib.optionalString (miniloader != null) ''
    cp ${miniloader}/*.bin "$FLASH_DIR/firmware/"
  '';

  copyImageCmds = builtins.concatStringsSep "\n" (
    builtins.attrValues (
      builtins.mapAttrs (_: project: ''
        cp -r ${project.image}/* "$FLASH_DIR/images/"
      '')
      targets
    )
  );

  copyUpgradeToolCmd = lib.optionalString (method == "upgrade_tool") ''
        cat > "$FLASH_DIR/config.ini" << 'EOF'
    [System]
    EOF
  '';

  # ── Flash scripts ────────────────────────────────────────────────

  miniloaderBin =
    if miniloader != null
    then builtins.head (builtins.attrNames (builtins.readDir "${miniloader}"))
    else "miniloader.bin";

  mkFlashScript = targetName: project: let
    imageName = builtins.head (builtins.attrNames (builtins.readDir "${project.image}"));
    imagePath = "images/${imageName}";
    scriptName = "flash-${targetName}.sh";
    targetMethod = if targetName == "spinand" then "upgrade_tool" else "dd";
  in
    if targetMethod == "upgrade_tool"
    then import ./scripts/flashUpgradeTool.nix {pkgs = nativePkgs; inherit miniloaderBin imagePath scriptName;}
    else import ./scripts/flashDd.nix {pkgs = nativePkgs; bootloaderFiles = cfg.bootloader.files; inherit imagePath scriptName;};

  flashScripts = builtins.mapAttrs mkFlashScript targets;

  copyFlashScriptCmds = builtins.concatStringsSep "\n" (
    builtins.attrValues (
      builtins.mapAttrs (targetName: script: ''
        cp ${script} "$FLASH_DIR/flash-${targetName}.sh"
        chmod +x "$FLASH_DIR/flash-${targetName}.sh"
      '') flashScripts
    )
  );

  # ── Packages ───────────────────────────────────────────────────

  hasSpinand = builtins.elem "spinand" (builtins.attrNames targets);

  methodPackages = (if hasSpinand then [nativePkgs.upgrade-tool] else []) ++ cfg.flash.extraPackages
    ++ [nativePkgs.usbutils nativePkgs.util-linux];
in
  nativePkgs.mkShell {
    name = "${cfg.board.name}-flash";

    packages = methodPackages;

    shellHook = ''
      FLASH_DIR=$(mktemp -d "/tmp/${cfg.board.name}-flash-XXXXXX")
      export FLASH_DIR

      mkdir -p "$FLASH_DIR/images" "$FLASH_DIR/firmware"

      ${copyBootloaderCmds}
      ${copyMiniloaderCmd}
      ${copyImageCmds}
      ${copyFlashScriptCmds}
      ${copyUpgradeToolCmd}

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
      echo "Images:"
      ls -la "$FLASH_DIR/images/"
      echo ""
      echo "Available flash scripts:"
      for s in "$FLASH_DIR"/flash-*.sh; do
        echo "  sudo $(basename $s)"
      done
      echo ""

      cd "$FLASH_DIR"
    '';
  }


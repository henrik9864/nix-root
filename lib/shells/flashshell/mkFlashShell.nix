{board}: let
  cfg = board.cfg;
  nativePkgs = cfg._nativePkgs;
  lib = nativePkgs.lib;

  bootloader = cfg.bootloader.package;
  method = cfg.flash.method;
  miniloader = cfg.flash.miniloader;
  image = cfg.flash.image;

  # ── Copy commands ────────────────────────────────────────────────

  copyBootloaderCmds = builtins.concatStringsSep "\n" (
    map (f: ''
      cp ${bootloader}/${f.file} "$FLASH_DIR/${f.file}"
    '')
    cfg.bootloader.files
  );

  copyMiniloaderCmd = lib.optionalString (miniloader != null) ''
    cp ${miniloader}/*.bin "$FLASH_DIR/"
  '';

  copyImageCmds = lib.optionalString (cfg.flash ? images && cfg.flash.images != []) (
    builtins.concatStringsSep "\n" (
      map (f: ''
        cp ${image}/${f.file} "$FLASH_DIR/${f.file}"
      '')
      cfg.flash.images
    )
  );

  copyImageCmd = lib.optionalString (cfg.flash ? image && cfg.flash ? imageName) ''
    cp ${image} "$FLASH_DIR/${cfg.flash.imageName}"
  '';

  copyUpgradeToolCmd = lib.optionalString (method == "upgrade_tool") ''
        cat > "$FLASH_DIR/config.ini" << 'EOF'
    [System]
    EOF
  '';

  # ── Per-method instructions ──────────────────────────────────────

  miniloaderBin =
    if miniloader != null
    then builtins.head (builtins.attrNames (builtins.readDir "${miniloader}"))
    else "miniloader.bin";

  upgradeToolSteps = ''
    echo "Steps:"
    echo "  1. Hold BOOT button and plug in USB"
    echo "  2. sudo upgrade_tool ld"
    echo "  3. sudo upgrade_tool db ${miniloaderBin}"
    echo "  4. sudo upgrade_tool ef                               # erase flash"
    echo "  5. sudo upgrade_tool wl 0x0 image.img                 # write full image"
    echo "  6. sudo upgrade_tool rd"
  '';

  ddSteps =
    ''
      echo "Steps:"
      echo "  1. Insert SD card / identify block device"
      echo "  2. Set device: export DEV=/dev/sdX"
    ''
    + builtins.concatStringsSep "" (
      map (f: ''
        echo "  3. sudo dd if=${f.file} of=\$DEV bs=512 seek=${toString f.offset} conv=notrunc"
      '')
      cfg.bootloader.files
    )
    + ''
      echo "  4. sync"
    '';

  stepsForMethod = {
    upgrade_tool = upgradeToolSteps;
    dd = ddSteps;
  };

  # ── Per-method packages ──────────────────────────────────────────

  methodPackages = {
    upgrade_tool = [nativePkgs.upgrade-tool];
    dd = [];
  };
in
  nativePkgs.mkShell {
    name = "${cfg.board.name}-flash";

    packages = (methodPackages.${method} or []) ++ cfg.flash.extraPackages;

    shellHook = ''
      FLASH_DIR=$(mktemp -d "/tmp/${cfg.board.name}-flash-XXXXXX")
      export FLASH_DIR

      ${copyBootloaderCmds}
      ${copyMiniloaderCmd}
      ${copyImageCmds}
      ${copyImageCmd}
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
      ls -la "$FLASH_DIR"
      echo ""
      ${stepsForMethod.${method}}
      echo ""

      cd "$FLASH_DIR"
    '';
  }

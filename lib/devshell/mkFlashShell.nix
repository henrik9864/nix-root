{ board }:

let
  cfg = board.cfg;
  nativePkgs = cfg._nativePkgs;
  lib = nativePkgs.lib;

  bootloader = cfg.bootloader.package;
  method     = cfg.flash.method;
  miniloader = cfg.flash.miniloader;

  # Copy bootloader files
  copyBootloaderCmds = builtins.concatStringsSep "\n" (
    map (f: ''
      cp ${bootloader}/${f.file} "$FLASH_DIR/${f.file}"
    '') cfg.bootloader.files
  );

  # Copy miniloader if present
    copyMiniloaderCmd = lib.optionalString (miniloader != null) ''
    cp ${miniloader}/miniloader.bin "$FLASH_DIR/miniloader.bin"
  '';

  rkdeveloptoolSteps = ''
    echo "Steps:"
    echo "  1. Hold BOOT button and plug in USB"
    echo "  2. sudo rkdeveloptool ld"
    echo "  3. sudo rkdeveloptool db miniloader.bin"
    echo "  4. sudo rkdeveloptool ef                              # erase flash"
    echo "  5. sudo rkdeveloptool wl 0x0 image.img                # write full image"
    echo "  6. sudo rkdeveloptool rd"
  '';

  ddSteps = ''
    echo "Steps:"
    echo "  1. Insert SD card / identify block device"
    echo "  2. Set device: export DEV=/dev/sdX"
  '' + builtins.concatStringsSep "" (
    map (f: ''
      echo "  3. sudo dd if=${f.file} of=\$DEV bs=512 seek=${toString f.offset} conv=notrunc"
    '') cfg.bootloader.files
  ) + ''
    echo "  4. sync"
  '';

  methodPackages = {
    rkdeveloptool = [ nativePkgs.rkdeveloptool ];
    dd            = [];
  };

in nativePkgs.mkShell {
  name = "${cfg.board.name}-flash";

  packages = (methodPackages.${method} or []) ++ cfg.flash.extraPackages;

  shellHook = ''
    FLASH_DIR=$(mktemp -d "/tmp/${cfg.board.name}-flash-XXXXXX")
    export FLASH_DIR

    ${copyBootloaderCmds}
    ${copyMiniloaderCmd}

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
    ${if method == "rkdeveloptool" then rkdeveloptoolSteps else ddSteps}
    echo ""

    cd "$FLASH_DIR"
  '';
}
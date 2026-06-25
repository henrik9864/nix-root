{targets}: let
  anyTarget = (builtins.attrValues targets) |> builtins.head;

  cfg = anyTarget.cfg;
  nativePkgs = cfg._nativePkgs;
  lib = nativePkgs.lib;
  bootloader = cfg.bootloader.package;
  method = cfg.flash.method;
  miniloader = cfg.flash.miniloader;

  copyBootloaderCmds =
    cfg.bootloader.files
    |> map (f: ''
      cp ${bootloader}/${f.file} "$FLASH_DIR/firmware/${f.file}"
    '')
    |> builtins.concatStringsSep "\n";

  copyMiniloaderCmd = lib.optionalString (miniloader != null) ''
    cp ${miniloader}/miniloader.bin "$FLASH_DIR/firmware/miniloader.bin"
  '';

  copyImageCmds =
    targets
    |> builtins.mapAttrs (_: project: ''
      cp -r ${project.image}/* "$FLASH_DIR/images/"
    '')
    |> builtins.attrValues
    |> builtins.concatStringsSep "\n";

  mkFlashScript = targetName: project: let
    scriptName = "flash-${targetName}.sh";
    # Derive disk image name from config — avoids import-from-derivation
    diskImageName = "${project.cfg.board.name}${project.cfg.output.imageSuffix}.img";
    imagePath = "images/${diskImageName}";
    method =
      if targetName == "spinand"
      then "spinand"
      else cfg.flash.method;
  in
    if method == "spinand"
    then
      import ./scripts/flashSpinand.nix {
        pkgs = nativePkgs;
        inherit lib scriptName;
        partitions = cfg.flash.spinandPartitions;
        miniloaderBin = "miniloader.bin";
      }
    else if method == "dd"
    then
      import ./scripts/flashDd.nix {
        pkgs = nativePkgs;
        bootloaderFiles = cfg.bootloader.files;
        inherit imagePath scriptName;
      }
    else throw "Unknown flash method: ${method}. Supported methods: spinand, dd";
  flashScripts = builtins.mapAttrs mkFlashScript targets;
  copyFlashScriptCmds =
    flashScripts
    |> builtins.mapAttrs (targetName: script: ''
      cp ${script} "$FLASH_DIR/flash-${targetName}.sh"
      chmod +x "$FLASH_DIR/flash-${targetName}.sh"
    '')
    |> builtins.attrValues
    |> builtins.concatStringsSep "\n";
  hasSpinand = builtins.hasAttr "spinand" targets;
  methodPackages =
    (
      if hasSpinand
      then [nativePkgs.upgrade-tool]
      else []
    )
    ++ cfg.flash.extraPackages
    ++ [nativePkgs.usbutils nativePkgs.util-linux nativePkgs.binutils];
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
      cd "$FLASH_DIR"
    '';
  }

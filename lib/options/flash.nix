{ lib, config, ... }:

let
  inherit (lib) mkOption types;
in {
  options.flash = {
    method = mkOption {
      type = types.enum [ "rkdeveloptool" "dd" ];
      default = "dd";
      description = ''
        Flash method for installing firmware onto the board.
        "rkdeveloptool" — Rockchip USB maskrom flashing.
        "dd"            — Direct sector writes to a block device.
      '';
    };

    miniloader = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Miniloader package (required for rkdeveloptool method).";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Extra packages to include in the flash devshell.";
    };
  };
}
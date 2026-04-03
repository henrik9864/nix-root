{ lib, config, ... }:

let
  inherit (lib) mkOption types;
in {
  options.flash = {
    method = mkOption {
      type = types.enum [ "rkdeveloptool" "upgrade_tool" "dd" ];
      default = "dd";
      description = ''
        Flash method for installing firmware onto the board.
        "rkdeveloptool" — Rockchip USB maskrom flashing (open-source).
        "upgrade_tool"  — Rockchip USB maskrom flashing (proprietary).
        "dd"            — Direct sector writes to a block device.
      '';
    };

    miniloader = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Miniloader package (required for rkdeveloptool/upgrade_tool methods).";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Extra packages to include in the flash devshell.";
    };
  };
}
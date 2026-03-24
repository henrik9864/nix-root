{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.uboot = {
    package = mkOption {
      type = types.package;
      description = "U-Boot package (e.g. pkgs.ubootOrangePi5).";
    };

    files = mkOption {
      type = types.listOf (types.submodule {
        options = {
          file = mkOption {
            type = types.str;
            description = "Filename inside the U-Boot package to flash.";
          };
          offset = mkOption {
            type = types.int;
            description = "Sector offset (512-byte sectors) to flash at.";
          };
        };
      });
      description = "List of U-Boot files to flash and their sector offsets.";
    };
  };
}
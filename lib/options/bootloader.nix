{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.bootloader = {
    package = mkOption {
      type = types.package;
      description = "Bootloader package (e.g. pkgs.ubootOrangePi5).";
    };

    files = mkOption {
      type = types.listOf (types.submodule {
        options = {
          file = mkOption {
            type = types.str;
            description = "Filename inside the bootloader package to flash.";
          };
          offset = mkOption {
            type = types.int;
            description = "Sector offset (512-byte sectors) to flash at.";
          };
        };
      });
      description = "List of bootloader files to flash and their sector offsets.";
    };
  };
}

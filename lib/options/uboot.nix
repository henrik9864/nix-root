{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.uboot = {
    package = mkOption {
      type = types.str;
      description = ''
        Attribute name of the U-Boot package in nixpkgs
        (e.g. "ubootOrangePi5").
      '';
    };

    idbloaderOffset = mkOption {
      type = types.int;
      default = 64;
      description = "Sector offset for idbloader.img.";
    };

    itbOffset = mkOption {
      type = types.int;
      default = 16384;
      description = "Sector offset for u-boot.itb.";
    };
  };
}
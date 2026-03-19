{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.image = {
    bootSizeMin = mkOption {
      type = types.int;
      default = 16;
      description = "Minimum boot partition size in MiB.";
    };

    rootfsSizeMin = mkOption {
      type = types.int;
      default = 16;
      description = "Minimum root partition size in MiB.";
    };

    bootPadding = mkOption {
      type = types.int;
      default = 8;
      description = "Extra padding added to the boot partition in MiB.";
    };

    rootfsPadding = mkOption {
      type = types.int;
      default = 16;
      description = "Extra padding added to the root partition in MiB.";
    };

    ubootReserved = mkOption {
      type = types.int;
      default = 32;
      description = "Space reserved for U-Boot at the start of the image (MiB).";
    };
  };
}
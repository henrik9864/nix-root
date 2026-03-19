{ lib, config, ... }:

let
  inherit (lib) mkOption types;

  cfg = config.output;

  targetDefaults = {
    sd = {
      rootDevice  = "/dev/mmcblk1p2";
      imageSuffix = "-sd";
    };
    emmc = {
      rootDevice  = "/dev/mmcblk0p2";
      imageSuffix = "-emmc";
    };
  };

  defaults = targetDefaults.${cfg.target};
in {
  options.output = {
    target = mkOption {
      type = types.enum [ "sd" "emmc" ];
      default = "sd";
      description = ''
        Boot target medium.
        'sd' generates an image for SD card (root=/dev/mmcblk1p2).
        'emmc' generates an image for eMMC (root=/dev/mmcblk0p2).
      '';
    };

    rootDevice = mkOption {
      type = types.str;
      default = defaults.rootDevice;
      description = ''
        Root device path used in the kernel command line.
        Derived from output.target if not set.
      '';
    };

    imageSuffix = mkOption {
      type = types.str;
      default = defaults.imageSuffix;
      description = ''
        Suffix appended to the image filename.
        Derived from output.target if not set.
      '';
    };
  };
}
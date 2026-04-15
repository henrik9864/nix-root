{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;

  cfg = config.output;

  targetDefaults = {
    sd = {
      rootDevice = "/dev/mmcblk1p2";
      imageSuffix = "-sd";
    };
    emmc = {
      rootDevice = "/dev/mmcblk0p2";
      imageSuffix = "-emmc";
    };
    spinand = {
      rootDevice = "/dev/mtdblock2";
      imageSuffix = "-spinand";
    };
  };

  defaults = targetDefaults.${cfg.target};
in {
  options.output = {
    targets = mkOption {
      type = types.listOf (types.enum ["sd" "emmc" "spinand"]);
      default = ["sd"];
      description = ''
        List of output targets this board supports.
        Used by the project registry to generate image variants.
      '';
    };

    target = mkOption {
      type = types.enum ["sd" "emmc" "spinand"];
      default = "sd";
      description = ''
        Boot target medium for this specific build.
        'sd' generates an image for SD card (root=/dev/mmcblk1p2).
        'emmc' generates an image for eMMC (root=/dev/mmcblk0p2).
        'spinand' generates an image for SPI NAND flash (root=/dev/mtdblock2).
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

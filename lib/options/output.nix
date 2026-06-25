{lib, config, ...}: let
  inherit (lib) mkOption types;

  cfg = config.output;

  targetDefaults = {
    sd = {
      rootDevice = "/dev/mmcblk1p2";
      imageSuffix = "-sd";
      rootfsType = "ext4";
    };
    emmc = {
      rootDevice = "/dev/mmcblk0p2";
      imageSuffix = "-emmc";
      rootfsType = "ext4";
    };
    spinand = {
      rootDevice = "ubi0:rootfs";
      imageSuffix = "-spinand";
      rootfsType = "ubifs";
    };
  };

  defaults = targetDefaults.${cfg.target};
in {
  options.output = {
    target = mkOption {
      type = types.enum ["sd" "emmc" "spinand"];
      default = "sd";
      description = ''
        Boot target medium for this specific build.
        'sd'      — SD card  (root=/dev/mmcblk1p2).
        'emmc'    — eMMC     (root=/dev/mmcblk0p2).
        'spinand' — SPI NAND (root=/dev/mtdblock4, rootfstype=jffs2).
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

    rootfsType = mkOption {
      type = types.str;
      default = defaults.rootfsType;
      description = ''
        Root filesystem type passed to the kernel (rootfstype=...).
        Derived from output.target if not set.
      '';
    };
  };
}

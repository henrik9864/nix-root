{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;

  partitionOpts = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Partition name (used in parameter.txt CMDLINE and flash step labels).";
      };
      sizeMiB = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Partition size in MiB. null fills the remaining flash space.";
      };
      offsetMiB = mkOption {
        type = types.int;
        description = "Partition start offset from flash start, in MiB.";
      };
      flashFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path relative to FLASH_DIR of the file to write to this partition. null skips writing.";
      };
    };
  };
in {
  options.flash = {
    method = mkOption {
      type = types.enum ["spinand" "dd"];
      default = "dd";
      description = ''
        Flash method for installing firmware onto the board.
        "dd"           — Direct sector writes to a block device.
      '';
    };

    miniloader = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Miniloader package (required for the upgrade_tool method).";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Extra packages to include in the flash devshell.";
    };

    spinandPartitions = mkOption {
      type = types.listOf partitionOpts;
      default = [];
      description = ''
        MTD partition layout for SPI NAND flash.
        Drives both parameter.txt generation and the per-partition upgrade_tool write commands.
        Sector offsets (512-byte units) are derived from offsetMiB at evaluation time.
      '';
    };

    nand = {
      pageSize = mkOption {
        type = types.int;
        default = 2048;
        description = "NAND page size in bytes.";
      };
      blockSize = mkOption {
        type = types.int;
        default = 131072;
        description = "NAND erase block size in bytes (128 KiB for most SPI NAND chips).";
      };
      totalSizeMiB = mkOption {
        type = types.int;
        description = "Total NAND flash capacity in MiB (used to size the last fill partition).";
      };
      dtFlashPath = mkOption {
        type = types.str;
        description = "Device tree node path of the SPI flash device (e.g. /spi@ffac0000/flash@0).";
      };
    };
  };
}

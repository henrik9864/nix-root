{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.spinand = {
    pageSize = mkOption {
      type = types.int;
      default = 2048;
      description = "NAND page size in bytes.";
    };

    eraseBlockSize = mkOption {
      type = types.int;
      default = 131072; # 128 KiB
      description = "NAND erase block size in bytes. Used as the JFFS2 erase unit size.";
    };

    envSizeKiB = mkOption {
      type = types.int;
      default = 1024; # 1 MiB
      description = "U-Boot env partition size in KiB.";
    };

    idblockSizeKiB = mkOption {
      type = types.int;
      default = 2048; # 2 MiB
      description = "IDB/loader partition size in KiB.";
    };

    ubootSizeKiB = mkOption {
      type = types.int;
      default = 256;
      description = "U-Boot partition size in KiB.";
    };

    miscSizeKiB = mkOption {
      type = types.int;
      default = 128;
      description = "Misc partition size in KiB.";
    };

    bootSizeKiB = mkOption {
      type = types.int;
      default = 16384; # 16 MiB
      description = "Boot partition size in KiB. Must fit the FIT image (kernel + DTB + initrd).";
    };

    kernelLoadAddr = mkOption {
      type = types.str;
      default = "0x00408000";
      description = "Kernel load and entry address passed to mkimage.";
    };

    initrdLoadAddr = mkOption {
      type = types.str;
      default = "0x0A000000";
      description = "Initial ramdisk load address passed to mkimage.";
    };

    envDataSizeKiB = mkOption {
      type = types.int;
      default = 32;
      description = "U-Boot environment size in KiB. Must match CONFIG_ENV_SIZE in the U-Boot defconfig.";
    };

    ubiVols = mkOption {
      type = types.listOf (types.attrs);
      default = [
        { id = 0; name = "boot"; size = 16 * 1024 * 1024; }    # 16 MiB for kernel/FIT
        { id = 1; name = "rootfs"; size = 128 * 1024 * 1024; } # 128 MiB for rootfs
      ];
      description = "UBI volumes for combined kernel/rootfs image. Each volume is an attribute set with id, name, and size (in bytes).";
    };

    ubiSubPageSize = mkOption {
      type = types.int;
      default = 2048;
      description = "UBI sub-page size in bytes (usually NAND page size). Used for mkfs.ubifs and ubinize -m argument.";
    };

    ubiPebSize = mkOption {
      type = types.int;
      default = 131072; # 128 KiB
      description = "UBI physical eraseblock size in bytes (used for ubinize -p argument). Should match eraseBlockSize.";
    };

    ubiMinSize = mkOption {
      type = types.int;
      default = 2048;
      description = "UBI minimum I/O unit size in bytes (used for ubinize -s argument). Usually NAND page size.";
    };
  };
}

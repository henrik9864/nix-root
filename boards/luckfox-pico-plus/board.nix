{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.kernel) yes;
in rec {
  board.name = "luckfox-pico-plus";
  board.crossSystem = "armv7l-unknown-linux-gnueabihf";
  board.dts = "sysdrv/source/kernel/arch/arm/boot/dts/rv1103g-luckfox-pico-plus.dts";

  board.dtbSource.git = {
    owner = "LuckfoxTECH";
    repo = "luckfox-pico";
    rev = "824b817f889c2cbff1d48fcdb18ab494a68f69d1";
    hash = "sha256-x5BC/hA9WCXqwrHJmcRv82NcWfV5jpOF+NTnRngRE70=";
    path = "sysdrv/source/kernel";
    sparseCheckout = ["sysdrv/source/kernel"];
  };

  bootloader.package = pkgs.uboot-luckfox-pico;
  bootloader.files = [
    {
      file = "u-boot.bin";
      offset = 64;
    }
  ];

  flash.method = "upgrade_tool";
  flash.miniloader = pkgs.rkbin-miniloader.override {iniFile = "RV1106MINIALL";};

  kernel.version = "7.0-rc6";
  kernel.modDirVersion = "7.0.0-rc6";
  kernel.imageFile = "zImage";

  kernel.git = {
    owner = "torvalds";
    repo = "linux";
    rev = "v7.0-rc6";
    hash = "sha256-hfBIYnBMpVVRo6hhcvHF2ZbjhSRDmaprJmarVQ1gqyA=";
  };

  kernel.structuredConfig = {
    ARCH_ROCKCHIP = yes;
    ROCKCHIP_PM_DOMAINS = yes;

    # MMC / SD / eMMC
    MMC = yes;
    MMC_SDHCI = yes;
    MMC_SDHCI_PLTFM = yes;
    MMC_SDHCI_OF_DWCMSHC = yes;

    # SPI
    SPI = yes;
    SPI_MASTER = yes;
    SPI_ROCKCHIP = yes; # Rockchip SPI controller

    # MTD / SPI NAND
    MTD = yes;
    MTD_BLOCK = yes;           # exposes NAND as /dev/mtdblockN
    MTD_SPI_NAND = yes;        # SPI NAND framework
    MTD_SPINAND_WINBOND = yes; # Winbond W25N (common on luckfox)
    MTD_SPINAND_GIGADEVICE = yes;
    MTD_SPINAND_MACRONIX = yes;
    MTD_SPINAND_TOSHIBA = yes;

    # JFFS2 — rootfs and boot partition filesystem on NAND
    JFFS2_FS = yes;
    JFFS2_FS_WRITEBUFFER = yes; # mandatory for NAND
    JFFS2_ZLIB = yes;
    JFFS2_RTIME = yes;
    LZO_COMPRESS = yes;
    JFFS2_LZO = yes;
  };

  image.bootPadding = 8;
  image.rootfsPadding = 16;

  serial.console = "ttyS2,1500000";

  output.targets = ["sd" "spinand"];
}

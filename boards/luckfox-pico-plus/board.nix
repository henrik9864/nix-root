{ lib, pkgs, ... }:

let
  inherit (lib.kernel) yes;
in {
  board.name        = "luckfox-pico-plus";
  board.crossSystem = "armv7l-unknown-linux-gnueabihf";
  board.dts         = "sysdrv/source/kernel/arch/arm/boot/dts/rv1103g-luckfox-pico-plus.dts";

  board.dtbSource.git = {
    owner          = "LuckfoxTECH";
    repo           = "luckfox-pico";
    rev            = "824b817f889c2cbff1d48fcdb18ab494a68f69d1";
    hash           = "sha256-x5BC/hA9WCXqwrHJmcRv82NcWfV5jpOF+NTnRngRE70=";
    path           = "sysdrv/source/kernel";
    sparseCheckout = [ "sysdrv/source/kernel" ];
  };

  bootloader.package = pkgs.uboot-luckfox-pico;
  bootloader.files = [
    { file = "u-boot.bin"; offset = 64; }
  ];

  # Add after the existing bootloader/kernel/image config:
  flash.method = "rkdeveloptool";
  flash.miniloader = pkgs.rkbin-miniloader;

  kernel.version       = "7.0-rc6";
  kernel.modDirVersion = "7.0.0-rc6";
  kernel.imageFile     = "zImage";

  kernel.git = {
    owner = "torvalds";
    repo  = "linux";
    rev   = "v7.0-rc6";
    hash  = "sha256-hfBIYnBMpVVRo6hhcvHF2ZbjhSRDmaprJmarVQ1gqyA=";
  };

  kernel.structuredConfig = {
    ARCH_ROCKCHIP        = yes;
    ROCKCHIP_PM_DOMAINS  = yes;
    MMC                  = yes;
    MMC_SDHCI            = yes;
    MMC_SDHCI_PLTFM      = yes;
    MMC_SDHCI_OF_DWCMSHC = yes;
  };

  image.bootPadding   = 8;
  image.rootfsPadding = 16;

  serial.console = "ttyS2,1500000";

  output.targets = [ "sd" ];
}
{ lib, pkgs, ... }:

let
  inherit (lib.kernel) yes;
in {
  board.name        = "luckfox-pico-plus";
  board.dtb         = "rv1103g-luckfox-pico-plus.dtb";
  board.crossSystem = "armv7l-unknown-linux-gnueabihf";

  uboot.package = pkgs.ubootBananaPi;

  kernel.version       = "7.0-rc4";
  kernel.modDirVersion = "7.0.0-rc4";

  kernel.git = {
    owner = "torvalds";
    repo  = "linux";
    rev   = "v7.0-rc4";
    hash  = "sha256-/57xoWrZy6GdhP7U9pvMJUrNWd3PJIVmxXjsT3OQpKQ=";
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

  rootfs.extraPackages = [ pkgs.curl ];

  rootfs.files = {
    "/etc/hostname" = { text = "luckfox-pico-plus"; };
  };
}
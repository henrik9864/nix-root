{ lib, pkgs, ... }:

let
  inherit (lib.kernel) yes;
in {
  # Board identity
  board.name = "radxa-cm5";
  board.dtb  = "rk3588s-radxa-cm5-io.dtb";

  # UBoot
  uboot.package = pkgs.ubootOrangePi5;

  # Linux kernel
  kernel.version       = "7.0-rc4";
  kernel.modDirVersion = "7.0.0-rc4";

  kernel.git = {
    owner = "torvalds";
    repo  = "linux";
    rev   = "v7.0-rc4";
    hash  = "sha256-/57xoWrZy6GdhP7U9pvMJUrNWd3PJIVmxXjsT3OQpKQ=";
  };

  kernel.structuredConfig = {
    ARCH_ROCKCHIP         = yes;
    ROCKCHIP_PM_DOMAINS   = yes;

    MMC                   = yes;
    MMC_SDHCI             = yes;
    MMC_SDHCI_PLTFM      = yes;
    MMC_SDHCI_OF_DWCMSHC = yes;
  };

  # Image
  image.bootPadding   = 8;
  image.rootfsPadding = 16;

  # Serial console
  serial.console = "ttyS2,1500000";

  # Rootfs
  rootfs.extraPackages = [
    pkgs.curl
  ];

  rootfs.files = {
    "/etc/hostname" = { text = "radxa-cm5"; };
  };
}
{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-custom.url = "path:./pkgs";
  };

  outputs = { self, nixpkgs, pkgs-custom }:
  let
    overlays = [
      (final: prev: import ./pkgs/default.nix { callPackage = final.callPackage; })
    ];

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      inherit overlays;
    };

    mkBoard = { boardModule, outputTarget }:
    let
      eval = import ./lib/options/options.nix {
        inherit nixpkgs overlays;
        modules = [
          boardModule
          { output.target = outputTarget; }
        ];
      };

      cfg = eval.config;

      bootloader = cfg.bootloader.package;
      kernel     = import ./lib/kernel/mkKernel.nix  { pkgs = cfg._pkgs;                               inherit cfg; };
      rootfs     = import ./lib/rootfs/mkRootfs.nix  { pkgs = cfg._pkgs; nativePkgs = cfg._nativePkgs; inherit cfg; };
      initrd     = import ./lib/initrd/mkInitrd.nix  { pkgs = cfg._nativePkgs;                         inherit rootfs; };
      image      = import ./lib/image/mkImage.nix   { pkgs = cfg._nativePkgs; inherit cfg bootloader kernel initrd rootfs; };
    in {
      inherit kernel rootfs initrd image;
    };

    radxaCm5Sd      = mkBoard { boardModule = ./boards/radxa-cm5.nix;         outputTarget = "sd"; };
    radxaCm5Emmc    = mkBoard { boardModule = ./boards/radxa-cm5.nix;         outputTarget = "emmc"; };
    luckfoxPicoPlus = mkBoard { boardModule = ./boards/luckfox-pico-plus.nix; outputTarget = "sd"; };
  in {
    packages.x86_64-linux = {
      radxaCm5 = {
        sd   = radxaCm5Sd.image;
        emmc = radxaCm5Emmc.image;
      };

      luckfoxPicoPlus = {
        sd = luckfoxPicoPlus.image;
      };
    };
  };
}
{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
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
      eval = import ./lib/options.nix {
        inherit nixpkgs overlays;
        modules = [
          boardModule
          { output.target = outputTarget; }
        ];
      };

      cfg = eval.config;

      uboot  = cfg.uboot.package;
      kernel = import ./lib/mkKernel.nix  { pkgs = cfg._pkgs; inherit cfg; };
      rootfs = import ./lib/mkRootfs.nix  { pkgs = cfg._pkgs; inherit cfg; };
      initrd = import ./lib/mkInitrd.nix  { pkgs = cfg._nativePkgs; inherit rootfs; };
      image  = import ./lib/mkImage.nix   { pkgs = cfg._nativePkgs; inherit cfg uboot kernel initrd rootfs; };
    in {
      inherit kernel rootfs initrd image;
    };

    radxaCm5Sd      = mkBoard { boardModule = ./boards/radxa-cm5.nix;         outputTarget = "sd"; };
    radxaCm5Emmc    = mkBoard { boardModule = ./boards/radxa-cm5.nix;         outputTarget = "emmc"; };
    luckfoxPicoPlus = mkBoard { boardModule = ./boards/luckfox-pico-plus.nix; outputTarget = "sd"; };
  in {
    packages.x86_64-linux = {
      inherit (pkgs) ubootLuckfoxPicoPlus;

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
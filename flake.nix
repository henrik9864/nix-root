{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    mkBoard = boardModule:
    let
      eval = import ./lib/options.nix {
        inherit nixpkgs;
        modules = [ boardModule ];
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

    radxaCm5 = mkBoard ./boards/radxa-cm5.nix;
  in {
    packages.x86_64-linux = {
      radxaCm5       = radxaCm5.image;
      radxaCm5Kernel = radxaCm5.kernel;
      radxaCm5Rootfs = radxaCm5.rootfs;
    };
  };
}
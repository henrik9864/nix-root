{
  description = "Nix flake for building custom sbc images";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    # Evaluate a board config into a full image + intermediate derivations
    mkBoard = boardModule:
    let
      # Evaluate all options with the board module applied
      eval = import ./lib/options.nix {
        inherit nixpkgs;
        modules = [ boardModule ];
      };

      cfg = eval.config;
      pkgs = cfg._pkgs;
      nativePkgs = cfg._nativePkgs;

      kernel = import ./lib/mkKernel.nix { inherit pkgs cfg; };
      rootfs = import ./lib/mkRootfs.nix { inherit pkgs cfg; };
      initrd = import ./lib/mkInitrd.nix { inherit pkgs rootfs; };
      image  = import ./lib/mkImage.nix  {
        pkgs = nativePkgs;
        inherit cfg kernel initrd rootfs;
        uboot = cfg._uboot;
      };

    in {
      inherit kernel rootfs initrd image;
    };

    radxaCm5 = mkBoard ./boards/radxa-cm5.nix;

  in {
    packages.x86_64-linux = {
      radxaCm5 = radxaCm5.image;
    };

    legacyPackages.x86_64-linux = {
      inherit (radxaCm5) kernel rootfs initrd image;
    };
  };
}
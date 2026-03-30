{
  description = "Custom packages and dev shells for nix-root";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [
        (final: prev: import ./default.nix { callPackage = final.callPackage; })
      ];
    };
  in {
    packages.x86_64-linux = {
      inherit (pkgs) barebox uboot-luckfox-pico;
    };
  };
}
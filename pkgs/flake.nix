{
  description = "Custom packages and dev shells for nix-root";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    customPkgs = pkgs.callPackage ./default.nix { };
  in {
    packages.x86_64-linux = customPkgs;

    devShells.x86_64-linux =
      let
        mkDevShell = pkg: pkg.overrideAttrs (_: {
          shellHook = ''
            echo ""
            echo "Build steps:"
            echo "  cd \$(mktemp -d)"
            echo "  unpackPhase"
            echo "  cd \$sourceRoot"
            echo "  patchPhase"
            echo "  configurePhase"
            echo "  buildPhase"
            echo ""
          '';
        });
      in {
        uboot-luckfox-pico = mkDevShell customPkgs.uboot-luckfox-pico;
        barebox             = mkDevShell customPkgs.barebox;
        rkbin-miniloader    = mkDevShell customPkgs.rkbin-miniloader;
      };
  };
}
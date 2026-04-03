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
        mkDevShell = pkg: pkg.overrideAttrs (old: {
          shellHook = ''
            BUILD_DIR=$(mktemp -d "/tmp/${pkg.pname}-XXXXXX")
            export BUILD_DIR

            cleanup() {
              rm -rf "$BUILD_DIR"
              echo "Cleaned up build dir: $BUILD_DIR"
            }
            trap cleanup EXIT

            installPhase() {
              ${old.installPhase or "echo 'No installPhase defined.'"}
            }
            export -f installPhase

            echo ""
            echo "══════════════════════════════════════════════════════"
            echo "  ${pkg.pname} dev shell"
            echo "  Build dir: $BUILD_DIR"
            echo "══════════════════════════════════════════════════════"
            echo ""
            echo "Build steps:"
            echo "  unpackPhase"
            echo "  cd \$sourceRoot"
            echo "  patchPhase"
            echo "  configurePhase"
            echo "  buildPhase"
            echo "  export out=\$BUILD_DIR/out"
            echo "  installPhase"
            echo ""

            cd "$BUILD_DIR"
          '';
        });
      in {
        uboot-luckfox-pico = mkDevShell customPkgs.uboot-luckfox-pico;
        barebox             = mkDevShell customPkgs.barebox;
        rkbin-miniloader    = mkDevShell customPkgs.rkbin-miniloader;
      };
  };
}
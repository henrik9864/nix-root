{
  description = "Custom packages and dev shells for nix-root";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    customPkgs = pkgs.callPackage ./default.nix {};
  in {
    packages.x86_64-linux = customPkgs;

    devShells.x86_64-linux = let
      mkDevShell = pkg:
        pkg.overrideAttrs (old: {
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

            runPhaseVar() {
              local name="$1"
              local body="''${!name-}"
              if [ -n "$body" ]; then
                eval "$body"
              elif declare -F "$name" >/dev/null; then
                "$name"
              else
                echo "No $name defined."
              fi
            }
            export -f runPhaseVar

            run-unpack() {
              echo ">>> unpackPhase"
              (cd "$BUILD_DIR" && runPhaseVar unpackPhase)
            }

            run-patch() {
              run-unpack
              cd "$BUILD_DIR/$sourceRoot"
              echo ">>> patchPhase"
              runPhaseVar patchPhase
            }

            run-configure() {
              run-patch
              echo ">>> configurePhase"
              runPhaseVar configurePhase
            }

            run-build() {
              run-configure
              echo ">>> buildPhase"
              runPhaseVar buildPhase
            }

            run-install() {
              run-build
              export out="$BUILD_DIR/out"
              mkdir -p "$out"
              echo ">>> installPhase"
              runPhaseVar installPhase
            }

            export -f run-unpack run-patch run-configure run-build run-install

            echo ""
            echo "══════════════════════════════════════════════════════"
            echo "  ${pkg.pname} dev shell"
            echo "  Build dir: $BUILD_DIR"
            echo "══════════════════════════════════════════════════════"
            echo ""
            echo "Jump commands (each runs all preceding steps first):"
            echo "  run-unpack"
            echo "  run-patch"
            echo "  run-configure"
            echo "  run-build"
            echo "  run-install"
            echo ""

            cd "$BUILD_DIR"
          '';
        });
    in {
      uboot-luckfox-pico = mkDevShell customPkgs.uboot-luckfox-pico;
      rkbin-miniloader = mkDevShell customPkgs.rkbin-miniloader;
    };
  };
}

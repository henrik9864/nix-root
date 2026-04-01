{ nixpkgs, modules, overlays ? [], extraArgs ? {} }:

let
  lib = (import nixpkgs { system = "x86_64-linux"; }).lib;

  inherit (lib) mkOption types;

  internalModule = { config, ... }:
  let
    cfg = config;

    crossPkgs = import nixpkgs {
      localSystem = cfg.board.buildSystem;
      crossSystem = { config = cfg.board.crossSystem; };
      inherit overlays;
    };
  in {
    options = {
      _pkgs = mkOption {
        type = types.attrs;
        internal = true;
      };

      _nativePkgs = mkOption {
        type = types.attrs;
        internal = true;
      };
    };

    config = {
      # Pure cross-compilation: buildPlatform != hostPlatform, no emulation.
      # Packages use the cross toolchain; target binaries are never executed
      # during the build.
      _pkgs = assert crossPkgs.stdenv.buildPlatform.system
           != crossPkgs.stdenv.hostPlatform.system
           || cfg.board.buildSystem == cfg.board.crossSystem;
        crossPkgs;

      _nativePkgs = import nixpkgs {
        system = cfg.board.buildSystem;
        inherit overlays;
      };

      _module.args.pkgs       = cfg._pkgs;
      _module.args.nativePkgs = cfg._nativePkgs;
    };
  };

  evaluated = lib.evalModules {
    modules = [
      ./board.nix
      ./bootloader.nix
      ./kernel.nix
      ./rootfs.nix
      ./image.nix
      ./serial.nix
      ./output.nix
      ./devshell.nix
      ./flash.nix
      internalModule
    ] ++ modules;

    specialArgs = extraArgs;
  };

in {
  config  = evaluated.config;
  options = evaluated.options;
}
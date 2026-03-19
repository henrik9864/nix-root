{ nixpkgs, modules }:

let
  lib = (import nixpkgs { system = "x86_64-linux"; }).lib;

  inherit (lib) mkOption types;

  internalModule = { config, ... }:
  let
    cfg = config;
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
      _pkgs = import nixpkgs {
        localSystem = cfg.board.buildSystem;
        crossSystem = { config = cfg.board.crossSystem; };
      };

      _nativePkgs = import nixpkgs {
        system = cfg.board.buildSystem;
      };

      _module.args.pkgs = cfg._pkgs;
    };
  };

  evaluated = lib.evalModules {
    modules = [
      ./options/board.nix
      ./options/uboot.nix
      ./options/kernel.nix
      ./options/rootfs.nix
      ./options/image.nix
      ./options/serial.nix
      internalModule
    ] ++ modules;
  };

in {
  config  = evaluated.config;
  options = evaluated.options;
}
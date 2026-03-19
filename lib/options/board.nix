{ lib, ... }:

let
  inherit (lib) mkOption types;
in {
  options.board = {
    name = mkOption {
      type = types.str;
      description = "Human-readable board name (used in derivation names).";
    };

    dtb = mkOption {
      type = types.str;
      description = "Device-tree blob filename (e.g. rk3588s-radxa-cm5-io.dtb).";
    };

    crossSystem = mkOption {
      type = types.str;
      default = "aarch64-unknown-linux-gnu";
      description = "Nix cross-compilation target triple.";
    };

    buildSystem = mkOption {
      type = types.str;
      default = "x86_64-linux";
      description = "Nix build (native) system.";
    };
  };
}
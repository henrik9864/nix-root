{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.board;
in {
  options.board = {
    name = mkOption {
      type = types.str;
      description = "Human-readable board name (used in derivation names).";
    };

    dtb = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Device-tree blob filename (e.g. rk3588s-radxa-cm5-io.dtb). Set this or board.dts, not both.";
    };

    dts = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Device-tree source filename (e.g. rv1103g-luckfox-pico-plus.dts). If set, compiled to a .dtb at build time.";
    };

    dtbSource = {
      git = {
        owner = mkOption {
          type = types.str;
          default = "";
          description = "GitHub repository owner.";
        };
        repo = mkOption {
          type = types.str;
          default = "";
          description = "GitHub repository name.";
        };
        rev = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Git revision (tag, branch, or commit hash).";
        };
        hash = mkOption {
          type = types.str;
          default = "";
          description = "Nix SRI hash of the git source.";
        };
        path = mkOption {
          type = types.str;
          default = "";
          description = "Path inside the repository.";
        };
        sparseCheckout = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "List of paths to sparse checkout. If empty, the full repo is fetched.";
        };
      };

      localPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Absolute path to the .dtb file. Use toString ./path/to/file.dtb in the board .nix.";
      };
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

    dtbPatches = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell commands to patch the DTB before packaging.
        The DTB file path is available as $DTB_PATH.
      '';
    };
  };
}

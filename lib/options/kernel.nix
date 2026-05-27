{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (lib.kernel) yes;

  cfg = config.kernel;

  detectedSrcType =
    if cfg.git.rev != ""
    then "git"
    else "tarball";
in {
  options.kernel = {
    version = mkOption {
      type = types.str;
      description = "Kernel version string (e.g. 7.0-rc4).";
    };

    modDirVersion = mkOption {
      type = types.str;
      description = "Module directory version (e.g. 7.0.0-rc4).";
    };

    srcType = mkOption {
      type = types.enum ["git" "tarball"];
      default = detectedSrcType;
      description = ''
        Kernel source type: 'git' for fetchFromGitHub, 'tarball' for fetchurl.
        Auto-detected from kernel.git.rev / kernel.tarball.url if not set.
      '';
    };

    git = {
      owner = mkOption {
        type = types.str;
        default = "torvalds";
        description = "GitHub repository owner.";
      };

      repo = mkOption {
        type = types.str;
        default = "linux";
        description = "GitHub repository name.";
      };

      rev = mkOption {
        type = types.str;
        default = "";
        description = "Git revision (tag, branch, or commit hash).";
      };

      hash = mkOption {
        type = types.str;
        default = "";
        description = "Nix SRI hash of the git source.";
      };
    };

    tarball = {
      url = mkOption {
        type = types.str;
        default = "";
        description = "URL to the kernel tarball (e.g. https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.0-rc4.tar.xz).";
      };

      hash = mkOption {
        type = types.str;
        default = "";
        description = "Nix SRI hash of the tarball.";
      };
    };

    structuredConfig = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Structured kernel config (lib.kernel.yes/no/module values).
        Merged on top of the base config.
      '';
    };

    baseConfig = mkOption {
      type = types.attrs;
      default = {
        EXT4_FS = yes;
        TMPFS = yes;
        BLK_DEV_INITRD = yes;
        RD_GZIP = yes;
        OF = yes;
        SERIAL_8250 = yes;
        SERIAL_8250_CONSOLE = yes;
        SERIAL_OF_PLATFORM = yes;
      };
      description = "Base kernel config. Board config is merged on top.";
    };

    enableCommonConfig = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NixOS common kernel config.";
    };

    autoModules = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically include all module options.";
    };

    preferBuiltin = mkOption {
      type = types.bool;
      default = true;
      description = "Prefer building options as built-in rather than modules.";
    };

    imageFile = mkOption {
      type = types.enum ["Image" "zImage"];
      default = "Image";
      description = "Kernel image filename to copy into the boot partition. Use 'zImage' for compressed ARM kernels.";
    };

    patches = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name for the patch (used in build logs).";
          };
          patch = mkOption {
            type = types.path;
            description = "Path to the .patch file.";
          };
        };
      });
      default = [];
      description = ''
        List of kernel patches to apply, in the same format as
        buildLinux.kernelPatches.
      '';
    };
  };
}

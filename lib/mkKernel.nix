{ pkgs, cfg }:

let
  mergedConfig = cfg.kernel.baseConfig // cfg.kernel.structuredConfig;

  src = if cfg.kernel.srcType == "git" then
    pkgs.fetchFromGitHub {
      inherit (cfg.kernel.git) owner repo rev hash;
    }
  else
    pkgs.fetchurl {
      inherit (cfg.kernel.tarball) url hash;
    };
in

pkgs.buildLinux {
  version       = cfg.kernel.version;
  modDirVersion = cfg.kernel.modDirVersion;

  inherit src;

  enableCommonConfig = cfg.kernel.enableCommonConfig;
  autoModules        = cfg.kernel.autoModules;
  preferBuiltin      = cfg.kernel.preferBuiltin;

  structuredExtraConfig = mergedConfig;

  extraMeta = {
    description = "Linux kernel for ${cfg.board.name}";
    platforms   = [ "aarch64-linux" ];
  };
}
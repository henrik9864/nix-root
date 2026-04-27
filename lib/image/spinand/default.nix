{
  pkgs,
  cfg,
  bootloader,
  kernel,
  initrd,
  rootfs,
}: let
  dtb = import ../common/dtb.nix {inherit pkgs cfg kernel;};
  inherit (dtb) dtbName dtbFile;

  s = cfg.spinand;

  ubootOffsetKiB = s.idblockSizeKiB;
  miscOffsetKiB = ubootOffsetKiB + s.ubootSizeKiB;
  bootOffsetKiB = miscOffsetKiB + s.miscSizeKiB;

  bootOffsetBytes = toString (bootOffsetKiB * 1024);
  bootSizeBytes = toString (s.bootSizeKiB * 1024);

  mtdParts =
    "mtdparts=rk-nand:"
    + "${toString s.idblockSizeKiB}K@0(idblock)"
    + ",${toString s.ubootSizeKiB}K@${toString ubootOffsetKiB}K(uboot)"
    + ",${toString s.miscSizeKiB}K@${toString miscOffsetKiB}K(misc)"
    + ",${toString s.bootSizeKiB}K@${toString bootOffsetKiB}K(boot)"
    + ",-(userdata)";

  bootArgs =
    "console=${cfg.serial.console} console=tty1"
    + " ${mtdParts}"
    + " root=${cfg.output.rootDevice}"
    + " rootfstype=${cfg.output.rootfsType}"
    + " rootwait rw init=/init";

  fitImageScript = import ./fitImage.nix {inherit pkgs cfg kernel initrd dtbName dtbFile bootArgs;};
  jffs2RootfsScript = import ./jffs2Rootfs.nix {
    inherit pkgs rootfs;
    eraseBlockSize = s.eraseBlockSize;
  };
  ubootEnvScript = import ./ubootEnv.nix {
    inherit pkgs bootArgs mtdParts bootOffsetBytes bootSizeBytes;
    envDataSizeKiB = s.envDataSizeKiB;
  };
  parameterFile = import ./parameter.nix {
    inherit pkgs mtdParts;
    boardName = cfg.board.name;
  };
in
  pkgs.stdenv.mkDerivation {
    name = "${cfg.board.name}-spinand-image";

    nativeBuildInputs = with pkgs; [
      ubootTools
      mtdutils
      dtc
    ];

    buildCommand = ''
      mkdir -p $out

      cp ${bootloader}/uboot.img  $out/uboot.img
      cp ${parameterFile}         $out/parameter.txt

      source ${fitImageScript}
      source ${jffs2RootfsScript}
      source ${ubootEnvScript}
    '';
  }

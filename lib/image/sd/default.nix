# SD card image: MBR disk image with FAT32 boot (extlinux) + ext4 rootfs.
# Bootloader is written at sector 64 (SD card layout).
{
  pkgs,
  cfg,
  bootloader,
  kernel,
  initrd,
  rootfs,
}: let
  imageSuffix = cfg.output.imageSuffix;
  imageName = "${cfg.board.name}${imageSuffix}.img";

  dtb = import ../common/dtb.nix {inherit pkgs cfg kernel;};
  inherit (dtb) dtbName dtbFile;

  calcSizes = import ../common/calcSizes.nix {inherit pkgs cfg kernel initrd rootfs dtbFile;};
  createImage = import ../common/createImage.nix {inherit pkgs cfg bootloader imageName;};
  bootPart = import ../common/bootPart.nix {inherit pkgs cfg kernel initrd dtbName dtbFile;};
  rootPart = import ../common/rootPart.nix {inherit pkgs rootfs;};
in
  pkgs.stdenv.mkDerivation {
    name = "${cfg.board.name}${imageSuffix}-image";

    nativeBuildInputs = with pkgs; [
      dosfstools
      mtools
      util-linux
      e2fsprogs
      coreutils
    ];

    buildCommand = ''
      source ${calcSizes}
      source ${createImage}
      source ${bootPart}
      source ${rootPart}
    '';
  }

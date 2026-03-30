{ pkgs, cfg, bootloader, kernel, initrd, rootfs }:

let
  imageSuffix = cfg.output.imageSuffix;
  imageName   = "${cfg.board.name}${imageSuffix}.img";

  # ── DTB resolution ───────────────────────────────────
  dtb = import ./dtb.nix { inherit pkgs cfg kernel; };
  inherit (dtb) dtbName dtbFile;

  # ── Build scripts ────────────────────────────────────
  calcSizes  = import ./calcSizes.nix  { inherit pkgs cfg kernel initrd rootfs dtbFile; };
  createImage = import ./createImage.nix { inherit pkgs cfg bootloader imageName; };
  bootPart   = import ./bootPart.nix   { inherit pkgs cfg kernel initrd dtbName dtbFile; };
  rootPart   = import ./rootPart.nix   { inherit pkgs rootfs; };

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
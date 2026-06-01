{
  pkgs,
  cfg,
  bootloader,
  kernel,
  rootfs,
  ...
}: let
  dtb = import ../common/dtb.nix {inherit pkgs cfg kernel;};
  inherit (dtb) dtsFile dtbFile;

  bootArgs =
    "keep_bootcon ignore_loglevel clk_ignore_unused"
    + " earlycon=uart8250,mmio32,0xff4c0000,115200"
    + " console=ttyS2,115200n8"
    + " rdinit=/init";

  parameterFile = import ./parameter.nix {
    inherit pkgs;
    mtdParts = "";
    boardName = cfg.board.name;
  };
in
  pkgs.stdenv.mkDerivation {
    name = "${cfg.board.name}-spinand-image";

    nativeBuildInputs = with pkgs; [
      ubootTools
      dtc
      cpio
    ];

    buildCommand = ''
      mkdir -p $out
      cp ${bootloader}/uboot.img $out/uboot.img
      cp ${kernel}/zImage        $out/kernel.img
      ${
        if dtsFile != null
        then "cp ${dtsFile} $out/devicetree.dts"
        else ""
      }
      cp ${parameterFile} $out/parameter.txt

      # Patch DTB
      cp ${dtbFile} $TMPDIR/devicetree.dtb
      chmod +w $TMPDIR/devicetree.dtb
      DTB_PATH=$TMPDIR/devicetree.dtb
      ${cfg.board.dtbPatches}
      fdtput -t s $DTB_PATH /chosen bootargs "${bootArgs}"
      cp $DTB_PATH $out/devicetree.dtb

      # Uncompressed cpio — vendor U-Boot auto-decompresses any gzip magic
      # it detects, so the data must be raw cpio (starts with 070701).
      cd ${rootfs}
      find . | cpio -H newc -o > $TMPDIR/initrd.cpio
      cd -
      mkimage \
        -A arm \
        -O linux \
        -T ramdisk \
        -C none \
        -a 0x00000000 \
        -e 0x00000000 \
        -n "initramfs" \
        -d $TMPDIR/initrd.cpio \
        $out/initrd.img
    '';
  }

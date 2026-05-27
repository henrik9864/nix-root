{
  pkgs,
  cfg,
  bootloader,
  kernel,
  initrd,
  rootfs,
}: let
  dtb = import ../common/dtb.nix {inherit pkgs cfg kernel;};
  inherit (dtb) dtbName dtsName dtbFile dtsFile dtbOutput;

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

  ubiImageScript = import ./ubiRootfs.nix {
    inherit pkgs cfg kernel initrd dtbName dtbFile rootfs;
    eraseBlockSize = s.eraseBlockSize;
    ubiMinSize = s.ubiMinSize;
    ubiSubPageSize = s.ubiSubPageSize;
    ubiPebSize = s.ubiPebSize;
    ubiVols = s.ubiVols;
    inherit bootArgs;
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

      # Fix DTB
      cp ${dtbFile} $TMPDIR/devicetree.dtb
      chmod +w $TMPDIR/devicetree.dtb
      fdtput -r $TMPDIR/devicetree.dtb /psci
			fdtput -t s $TMPDIR/devicetree.dtb /chosen bootargs \
        "earlycon=uart8250,mmio32,0xff4c0000 console=ttyS2,1500000 rw init=/init"
      cp $TMPDIR/devicetree.dtb $out/devicetree.dtb

      # Pack rootfs as initramfs
      cd ${rootfs}
      find . | cpio -H newc -o > $TMPDIR/initrd.cpio
      cd -
      mkimage -A arm -O linux -T ramdisk -C none \
        -a 0x00000000 -e 0x00000000 \
        -n "initramfs" \
        -d $TMPDIR/initrd.cpio $out/initrd.img

      source ${ubiImageScript}
      source ${ubootEnvScript}
    '';
  }

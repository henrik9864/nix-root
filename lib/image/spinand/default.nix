{
  pkgs,
  cfg,
  bootloader,
  kernel,
  rootfs,
  ...
}: let
  lib = pkgs.lib;
  dtb = import ../common/dtb.nix {inherit pkgs cfg kernel;};
  inherit (dtb) dtsFile dtbFile;

  lebSize = cfg.flash.nand.blockSize - 2 * cfg.flash.nand.pageSize;

  bootArgs =
    "keep_bootcon ignore_loglevel clk_ignore_unused"
    + lib.optionalString (cfg.serial.earlycon != null) " earlycon=${cfg.serial.earlycon}"
    + " console=${cfg.serial.console}n8"
    + " ubi.mtd=rootfs root=${cfg.output.rootDevice} rootfstype=${cfg.output.rootfsType} init=/init";

  mibToBytes = mib: mib * 1024 * 1024;
  toHex = n: "0x${lib.toHexString n}";

  flashPath = cfg.flash.nand.dtFlashPath;
  totalNandBytes = mibToBytes cfg.flash.nand.totalSizeMiB;

  partSize = p:
    if p.sizeMiB == null
    then totalNandBytes - mibToBytes p.offsetMiB
    else mibToBytes p.sizeMiB;

  mkPartitionCmds = p: let
    path = "${flashPath}/partitions/partition@${lib.toHexString (mibToBytes p.offsetMiB)}";
    offsetBytes = mibToBytes p.offsetMiB;
    sizeBytes = partSize p;
  in ''
    fdtput -c $DTB_PATH "${path}"
    fdtput -t s $DTB_PATH "${path}" label "${p.name}"
    fdtput -t u $DTB_PATH "${path}" reg ${toString offsetBytes} ${toString sizeBytes}
  '';

  dtbPatchCmds = ''
    ${cfg.board.dtbPatches}
    fdtput -t s $DTB_PATH /chosen bootargs "${bootArgs}"
    fdtput -r $DTB_PATH "${flashPath}/partitions" 2>/dev/null || true
    fdtput -c $DTB_PATH "${flashPath}/partitions"
    fdtput -t s $DTB_PATH "${flashPath}/partitions" compatible "fixed-partitions"
    fdtput -t u $DTB_PATH "${flashPath}/partitions" "#address-cells" 1
    fdtput -t u $DTB_PATH "${flashPath}/partitions" "#size-cells" 1
    ${lib.concatMapStrings mkPartitionCmds cfg.flash.spinandPartitions}
  '';

  parameterFile = import ./parameter.nix {inherit pkgs cfg;};
in
  pkgs.stdenv.mkDerivation {
    name = "${cfg.board.name}-spinand-image";

    nativeBuildInputs = with pkgs; [
      ubootTools
      dtc
      mtdutils
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

      cp ${dtbFile} $TMPDIR/devicetree.dtb
      chmod +w $TMPDIR/devicetree.dtb
      DTB_PATH=$TMPDIR/devicetree.dtb
      ${dtbPatchCmds}
      cp $DTB_PATH $out/devicetree.dtb

      mkfs.ubifs \
        -r ${rootfs} \
        -m ${toString cfg.flash.nand.pageSize} \
        -e ${toString lebSize} \
        -c 2048 \
        -o $TMPDIR/rootfs.ubifs

      cat > $TMPDIR/ubinize.ini << EOF
      [rootfs-volume]
      mode=ubi
      image=$TMPDIR/rootfs.ubifs
      vol_id=0
      vol_type=dynamic
      vol_name=rootfs
      vol_flags=autoresize
      EOF

      ubinize \
        -o $out/rootfs.ubi \
        -m ${toString cfg.flash.nand.pageSize} \
        -p ${toString cfg.flash.nand.blockSize} \
        $TMPDIR/ubinize.ini
    '';
  }

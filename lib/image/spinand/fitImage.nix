{
  pkgs,
  cfg,
  kernel,
  initrd,
  dtbName,
  dtbFile,
  bootArgs,
}: let
  s = cfg.spinand;
  kernelImageFile = cfg.kernel.imageFile;

  bootIts = ''
    /dts-v1/;
    / {
      description = "${cfg.board.name} boot image";
      #address-cells = <1>;

      images {
        kernel@1 {
          description = "Linux kernel";
          data = /incbin/("${kernelImageFile}");
          type = "kernel";
          arch = "arm";
          os = "linux";
          compression = "none";
          load = <${s.kernelLoadAddr}>;
          entry = <${s.kernelLoadAddr}>;
          hash@1 { algo = "crc32"; };
        };

        fdt@1 {
          description = "Flattened Device Tree blob";
          data = /incbin/("${dtbName}");
          type = "flat_dt";
          arch = "arm";
          compression = "none";
          hash@1 { algo = "crc32"; };
        };

        ramdisk@1 {
          description = "Initial ramdisk";
          data = /incbin/("initrd");
          type = "ramdisk";
          arch = "arm";
          os = "linux";
          compression = "none";
          load = <${s.initrdLoadAddr}>;
          entry = <${s.initrdLoadAddr}>;
          hash@1 { algo = "crc32"; };
        };
      };

      configurations {
        default = "conf@1";
        conf@1 {
          description = "${cfg.board.name}";
          kernel = "kernel@1";
          fdt = "fdt@1";
          ramdisk = "ramdisk@1";
        };
      };
    };
  '';
in
  pkgs.writeShellScript "fit-image.sh" ''
    WORKDIR=$(mktemp -d)
    trap 'rm -rf "$WORKDIR"' EXIT

    cp ${dtbFile} "$WORKDIR/device.dtb"
    chmod u+w "$WORKDIR/device.dtb"
    fdtput -t s "$WORKDIR/device.dtb" /chosen bootargs "${bootArgs}"

    mkdir -p "$WORKDIR/fit-staging"
    cp ${kernel}/${kernelImageFile} "$WORKDIR/fit-staging/${kernelImageFile}"
    cp "$WORKDIR/device.dtb"        "$WORKDIR/fit-staging/${dtbName}"
    cp ${initrd}/initrd             "$WORKDIR/fit-staging/initrd"

    cat > "$WORKDIR/fit-staging/boot.its" << 'ITS'
    ${bootIts}
    ITS

    (cd "$WORKDIR/fit-staging" && mkimage -f boot.its "$WORKDIR/boot.img")
    cp "$WORKDIR/boot.img" $out/boot.img
  ''


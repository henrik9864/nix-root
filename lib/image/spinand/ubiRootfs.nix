{
  pkgs,
  cfg,
  kernel,
  initrd,
  dtbName,
  dtbFile,
  rootfs,
  eraseBlockSize,
  ubiMinSize,
  ubiSubPageSize,
  ubiPebSize,
  ubiVols,
  bootArgs,
}: let
  fitImageScript = import ./fitImage.nix {
    inherit pkgs cfg kernel initrd dtbName dtbFile bootArgs;
  };

  # Generate proper ubinize config
  mkUbiConfig = builtins.concatStringsSep "\n" (map (vol: let
    image =
      if vol.name == "boot"
      then "boot.img"
      else if vol.name == "rootfs"
      then "rootfs.ubifs"
      else throw "Unknown UBI volume: ${vol.name}";
    volType =
      if vol.name == "boot"
      then "static"
      else "dynamic";
  in ''
    [${vol.name}]
    mode=ubi
    image=${image}
    vol_id=${toString vol.id}
    vol_type=${volType}
    vol_name=${vol.name}
    ${
      if vol.name == "rootfs"
      then "vol_flags=autoresize"
      else ""
    }
  '') ubiVols);
in
  pkgs.writeShellScript "ubi-rootfs.sh" ''
        set -e
        set -x
        WORKDIR=$(mktemp -d)
        trap 'rm -rf "$WORKDIR"' EXIT
        cd "$WORKDIR"

        # Build the FIT image
        source ${fitImageScript}
        cp $out/boot.img ./boot.img

        # Copy rootfs
        cp -r --no-preserve=mode,ownership ${rootfs} ./rootfs
        chmod -R u+w ./rootfs

        ls .

        # Create UBI config file
        cat > ./ubi.cfg << EOF
${mkUbiConfig}
EOF

        # Create UBIFS image (rootfs)
        mkfs.ubifs \
          -r ./rootfs \
          -o ./rootfs.ubifs \
          -m ${toString ubiSubPageSize} \
          -e ${toString eraseBlockSize} \
          -c 2047

        # Create UBI image
        ubinize \
          -o ./system.img \
          -m ${toString ubiSubPageSize} \
          -p ${toString ubiPebSize} \
          -s ${toString ubiMinSize} \
          ./ubi.cfg

        cp ./system.img $out/system.img
  ''

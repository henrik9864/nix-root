{
  pkgs,
  bootArgs,
  mtdParts,
  bootOffsetBytes,
  bootSizeBytes,
  envDataSizeKiB,
}:
pkgs.writeShellScript "uboot-env.sh" ''
  cat > env.txt << ENVEOF
  bootargs=${bootArgs}
  mtdparts=${mtdParts}
  bootcmd=nand read ''${loadaddr} ${bootOffsetBytes} ${bootSizeBytes}; bootm ''${loadaddr}
  ENVEOF
  mkenvimage -s ${toString (envDataSizeKiB * 1024)} -o $out/env.img env.txt
''

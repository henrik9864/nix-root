{
  pkgs,
  cfg,
}:
let
  mkMtdPart = p:
    if p.sizeMiB == null
    then "-(${p.name})"
    else
      let offsetStr = if p.offsetMiB == 0 then "0" else "${toString p.offsetMiB}M";
      in "${toString p.sizeMiB}M@${offsetStr}(${p.name})";
  mtdParts = "mtdparts=rk-nand:" + builtins.concatStringsSep "," (map mkMtdPart cfg.flash.spinandPartitions);
in
  pkgs.writeText "parameter.txt" ''
    FIRMWARE_VER:1.0
    MACHINE_MODEL:${cfg.board.name}
    MACHINE_ID:007
    MANUFACTURER:custom
    MAGIC:0x5041524B
    ATAG:0x00200800
    MACHINE:0
    CHECK_MASK:0x80
    PWR_HLD:0,0,A,0,1
    TYPE:MTD
    CMDLINE:${mtdParts}
  ''

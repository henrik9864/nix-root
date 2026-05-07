{
  pkgs,
  boardName,
  mtdParts,
}:
pkgs.writeText "parameter.txt" ''
FIRMWARE_VER:1.0
MACHINE_MODEL:${boardName}
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

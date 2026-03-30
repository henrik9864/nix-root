{ callPackage }:

{
  barebox            = callPackage ./barebox { };
  uboot-luckfox-pico = callPackage ./uboot-luckfox-pico { };
}
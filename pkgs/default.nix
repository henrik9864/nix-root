{callPackage}: {
  barebox = callPackage ./barebox {};
  uboot-luckfox-pico = callPackage ./uboot-luckfox-pico {};
  rkbin-miniloader = callPackage ./rkbin-miniloader {};
  upgrade-tool = callPackage ./upgrade-tool {};
}

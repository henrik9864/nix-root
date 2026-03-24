{ buildUBoot, fetchFromGitHub }:

buildUBoot {
  defconfig = "luckfox_pico_rv1103_defconfig";
  extraMeta.platforms = [ "armv7l-linux" ];
  filesToInstall = [ "u-boot.bin" ];

  src = fetchFromGitHub {
    owner = "LuckfoxTECH";
    repo  = "luckfox-pico";
    rev   = "v2.0";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  sourceRoot = "source/sysdrv/source/uboot/u-boot-2017.09";
}
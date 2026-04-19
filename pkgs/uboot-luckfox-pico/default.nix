{
  lib,
  stdenv,
  fetchFromGitHub,
  bison,
  flex,
  bc,
  python3,
  swig,
  dtc,
  openssl,
  pkg-config,
  gcc-arm-embedded,
  buildPackages,
  defconfig ? "luckfox_rv1106_uboot",
}: let
  kcflags = "-Wno-error=enum-int-mismatch -Wno-error=address -Wno-error=maybe-uninitialized";
  hostcc = lib.getExe buildPackages.stdenv.cc;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "uboot-luckfox-pico";
    version = "latest-luckfox";

    src = fetchFromGitHub {
      owner = "LuckfoxTECH";
      repo = "luckfox-pico";
      rev = "824b817f889c2cbff1d48fcdb18ab494a68f69d1";
      hash = "sha256-X+L8hyw0vVCnP6dE+NUsPBoE9UszNCel/RNPFb72jIg=";
      sparseCheckout = ["sysdrv/source/uboot" "sysdrv/source/uboot/rkbin"];
    };

    sourceRoot = "${finalAttrs.src.name}/sysdrv/source/uboot/u-boot";

    depsBuildBuild = [
      buildPackages.stdenv.cc
      buildPackages.bison
      buildPackages.flex
    ];

    nativeBuildInputs = [
      bison
      flex
      bc
      python3
      swig
      dtc
      openssl
      pkg-config
      gcc-arm-embedded
    ];

    enableParallelBuilding = true;

    postUnpack = ''
      chmod -R u+w "${finalAttrs.src.name}"
    '';

    postPatch = ''
      patchShebangs .
    '';

    buildPhase = ''
      runHook preBuild
      KCFLAGS="${kcflags}" ./make.sh ${defconfig} --spl-new CROSS_COMPILE=arm-none-eabi-
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp u-boot.bin $out/
      cp *_download_*.bin $out/miniall.bin
      cp *_idblock_*.img $out/idblock.img
      runHook postInstall
    '';

    meta = with lib; {
      description = "U-Boot bootloader for Luckfox Pico Plus (from Luckfox Pico SDK)";
      homepage = "https://github.com/LuckfoxTECH/luckfox-pico";
      license = licenses.gpl2Only;
      maintainers = [];
      platforms = platforms.linux;
    };
  })

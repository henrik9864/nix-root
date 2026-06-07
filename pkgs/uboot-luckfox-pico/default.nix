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
  which,
  buildPackages,
  defconfig ? "luckfox_rv1106_uboot",
  bootcmd ? null,
  configOverrides ? {CONFIG_SPL_FIT_HW_CRYPTO = false;},
}: let
  kcflags = "-Wno-error=enum-int-mismatch -Wno-error=address -Wno-error=maybe-uninitialized";
  applyConfigOverrides = let
    applyOverride = name: value:
      if value == true
      then "${name}=y"
      else if value == false
      then "# ${name} is not set"
      else "${name}=${value}";
  in
    lib.concatStringsSep "\n" (lib.mapAttrsToList applyOverride configOverrides);
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
      which
    ];

    enableParallelBuilding = true;

    postUnpack = ''
      chmod -R u+w "${finalAttrs.src.name}"
    '';

    postPatch = ''
      patchShebangs .

      sed -i '/\t\t\tsignature {/,/\t\t\t};/d' arch/arm/mach-rockchip/fit_nodes.sh
    '' + lib.optionalString (bootcmd != null) (
      let bootcmdSed = builtins.replaceStrings ["&"] ["\\&"] bootcmd;
      in ''

      sed -i 's|^#define CONFIG_BOOTCOMMAND.*|#define CONFIG_BOOTCOMMAND "${bootcmdSed}"|' include/configs/*.h
    '');

    configurePhase = ''
      runHook preConfigure
      make ${defconfig}_defconfig CROSS_COMPILE=arm-none-eabi-
      ${lib.optionalString (configOverrides != {}) ''        cat >> .config <<EOF
        ${applyConfigOverrides}
        EOF
      ''}
      make olddefconfig CROSS_COMPILE=arm-none-eabi-
      cp .config configs/${defconfig}_nix_defconfig
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      KCFLAGS="${kcflags}" ./make.sh ${defconfig}_nix CROSS_COMPILE=arm-none-eabi-
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp uboot.img $out/
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

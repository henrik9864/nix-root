{ lib
, stdenv
, fetchFromGitHub
, bison
, flex
, bc
, python3
, swig
, dtc
, openssl
, pkg-config
, gcc-arm-embedded
, buildPackages

, defconfig ? "luckfox_rv1106_uboot_defconfig"
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "uboot-luckfox-pico";
  version = "latest-luckfox";

  src = fetchFromGitHub {
    owner  = "LuckfoxTECH";
    repo   = "luckfox-pico";
    rev    = "824b817f889c2cbff1d48fcdb18ab494a68f69d1";
    hash   = "sha256-X+L8hyw0vVCnP6dE+NUsPBoE9UszNCel/RNPFb72jIg=";
    sparseCheckout = [ "sysdrv/source/uboot" ];
  };

  sourceRoot = "${finalAttrs.src.name}/sysdrv/source/uboot";

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

  postPatch = ''
    patchShebangs scripts/
    patchShebangs tools/
  '';

  configurePhase = ''
    runHook preConfigure
    make HOSTCC=${lib.getExe buildPackages.stdenv.cc} \
         ARCH=arm \
         CROSS_COMPILE=arm-none-eabi- \
         ${defconfig}
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    make HOSTCC=${lib.getExe buildPackages.stdenv.cc} \
         ARCH=arm \
         CROSS_COMPILE=arm-none-eabi- \
         all
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    for f in u-boot.bin u-boot-dtb.bin u-boot.img u-boot-nodtb.bin; do
      [ -f "$f" ] && cp "$f" $out/
    done
    if [ -d tpl ]; then
      for f in tpl/u-boot-tpl.bin; do
        [ -f "$f" ] && cp "$f" $out/
      done
    fi
    if [ -d spl ]; then
      for f in spl/u-boot-spl.bin; do
        [ -f "$f" ] && cp "$f" $out/
      done
    fi
    echo "=== u-boot build outputs ==="
    ls -la $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "U-Boot bootloader for Luckfox Pico Plus (from Luckfox Pico SDK)";
    homepage    = "https://github.com/LuckfoxTECH/luckfox-pico";
    license     = licenses.gpl2Only;
    maintainers = [ ];
    platforms   = platforms.linux;
  };
})
{
  lib,
  stdenv,
  fetchurl,
  bison,
  flex,
  openssl,
  pkg-config,
  perl,
  python3,
  hostname,
  gcc-arm-embedded,
  lz4,
  buildPackages,
  defconfig ? "rockchip_v7a_defconfig",
  extraConfig ? "",
  version ? "2026.03.1",
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "barebox";
  inherit version;

  src = fetchurl {
    url = "https://www.barebox.org/download/barebox-${finalAttrs.version}.tar.bz2";
    hash = "sha256-nksjcgAWu5NNxeo21MM4hqiilURdKQuZmT0LMsqrZGk=";
  };

  depsBuildBuild = [
    buildPackages.stdenv.cc
    buildPackages.bison
    buildPackages.flex
  ];

  nativeBuildInputs = [
    openssl
    pkg-config
    perl
    python3
    hostname
    gcc-arm-embedded
    bison
    flex
    lz4
  ];

  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs scripts/
  '';

  configurePhase = ''
    runHook preConfigure
    make HOSTCC=${lib.getExe buildPackages.stdenv.cc} \
         ARCH=arm \
         CROSS_COMPILE=arm-none-eabi- \
         ${defconfig}
    ${lib.optionalString (extraConfig != "") ''
      echo "${extraConfig}" >> .config
      make HOSTCC=${lib.getExe buildPackages.stdenv.cc} \
           ARCH=arm \
           CROSS_COMPILE=arm-none-eabi- \
           olddefconfig
    ''}
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    make HOSTCC=${lib.getExe buildPackages.stdenv.cc} \
         ARCH=arm \
         CROSS_COMPILE=arm-none-eabi-
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    # Copy top-level binaries
    for f in barebox barebox.bin barebox.img; do
      [ -f "$f" ] && cp "$f" $out/
    done
    # Copy everything from images/
    if [ -d images ]; then
      cp images/* $out/ 2>/dev/null || true
    fi
    echo "=== barebox build outputs ==="
    ls -la $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Barebox bootloader";
    homepage = "https://www.barebox.org";
    license = licenses.gpl2Only;
    maintainers = [];
    platforms = platforms.linux;
  };
})

{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  autoPatchelfHook,
  stdenv,
  zlib,
  iniFile ? "RV1106MINIALL",
}:
stdenvNoCC.mkDerivation {
  pname = "rkbin-miniloader-${lib.toLower iniFile}";
  version = "unstable-2025-06-13";

  src = fetchFromGitHub {
    owner = "rockchip-linux";
    repo = "rkbin";
    rev = "74213af1e952c4683d2e35952507133b61394862";
    hash = "sha256-gNCZwJd9pjisk6vmvtRNyGSBFfAYOADTa5Nd6Zk+qEk=";
  };

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [zlib stdenv.cc.cc.lib];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    chmod +x tools/boot_merger
    ./tools/boot_merger "RKBOOT/${iniFile}.ini"

    mkdir -p $out
    outFile=$(grep -i '^PATH=' "RKBOOT/${iniFile}.ini" | cut -d= -f2 | tr -d '[:space:]')
    cp "$outFile" $out/
  '';

  meta = with lib; {
    description = "Rockchip miniloader and flash tools from rkbin for ${iniFile}";
    homepage = "https://github.com/rockchip-linux/rkbin";
    license = licenses.unfreeRedistributableFirmware;
    platforms = platforms.linux;
  };
}

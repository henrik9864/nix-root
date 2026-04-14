{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  autoPatchelfHook,
  stdenv,
  zlib,
}:
stdenvNoCC.mkDerivation {
  pname = "upgrade-tool";
  version = "2.1";

  src = fetchFromGitHub {
    owner = "vicharak-in";
    repo = "Linux_Upgrade_Tool";
    rev = "266e4c0f59d36a5f9b395a78255d6af04222279c";
    hash = "sha256-G5JeQiJXJVS/biBH07JxU3uNSq1gJfNqT1BHH2Iwm48=";
  };

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [zlib stdenv.cc.cc.lib];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp upgrade_tool $out/bin/upgrade_tool
    chmod +x $out/bin/upgrade_tool
  '';

  meta = with lib; {
    description = "Rockchip Linux Upgrade Tool v2.1";
    homepage = "https://github.com/vicharak-in/Linux_Upgrade_Tool";
    license = licenses.unfreeRedistributableFirmware;
    platforms = ["x86_64-linux"];
  };
}

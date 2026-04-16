# Resolves the DTB file: either compiles from .dts or locates a prebuilt .dtb
{
  pkgs,
  cfg,
  kernel,
}: let
  dtbSource = cfg.board.dtbSource;

  dtbName =
    if cfg.board.dts != ""
    then builtins.replaceStrings [".dts"] [".dtb"] (baseNameOf cfg.board.dts)
    else cfg.board.dtb;

  fetchedGitSource =
    if dtbSource.type == "git"
    then
      pkgs.fetchFromGitHub ({
          inherit (dtbSource.git) owner repo rev hash;
        }
        // (
          if dtbSource.git.sparseCheckout != []
          then {
            sparseCheckout = dtbSource.git.sparseCheckout;
          }
          else {}
        ))
    else null;

  sourceDir =
    if dtbSource.type == "kernel"
    then kernel
    else if dtbSource.type == "git"
    then fetchedGitSource
    else dtbSource.localPath;

  compileDtb = let
    dtsPath = "${sourceDir}/${cfg.board.dts}";
    dtsFileDir = builtins.dirOf dtsPath;
    includeDir = "${sourceDir}/${dtbSource.git.path}/include";
  in
    pkgs.stdenv.mkDerivation {
      name = "dtb-${dtbName}";
      nativeBuildInputs = [pkgs.dtc pkgs.gcc];
      buildCommand = ''
        cpp -nostdinc \
            -I ${includeDir} \
            -I ${dtsFileDir} \
            -undef -x assembler-with-cpp \
            ${dtsPath} \
            -o preprocessed.dts

        dtc -I dts -O dtb \
            -i ${includeDir} \
            -i ${dtsFileDir} \
            -o $out \
            preprocessed.dts
      '';
    };

  dtbFile =
    if cfg.board.dts != ""
    then "${compileDtb}"
    else if dtbSource.type == "kernel"
    then "${kernel}/dtbs/rockchip/${dtbName}"
    else if dtbSource.type == "git"
    then "${fetchedGitSource}/${dtbSource.git.path}"
    else dtbSource.localPath;
in {
  inherit dtbName dtbFile;
}

# Resolves/compiles DTB from DTS and exposes both DTS + DTB outputs
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

  dtsName =
    if cfg.board.dts != ""
    then baseNameOf cfg.board.dts
    else builtins.replaceStrings [".dtb"] [".dts"] dtbName;

  fetchedGitSource =
    if dtbSource.type == "git"
    then
      pkgs.fetchFromGitHub ({
          inherit (dtbSource.git) owner repo rev hash;
        }
        // (
          if dtbSource.git.sparseCheckout != []
          then { inherit (dtbSource.git) sparseCheckout; }
          else {}
        ))
    else null;

  sourceDir =
    if dtbSource.type == "kernel"
    then kernel
    else if dtbSource.type == "git"
    then "${fetchedGitSource}/${dtbSource.git.path}"
    else dtbSource.localPath;

  dtsPath = "${sourceDir}/${cfg.board.dts}";
  dtsFileDir = builtins.dirOf dtsPath;
  includeDir = "${sourceDir}/include";

  compileDtb =
    pkgs.stdenv.mkDerivation {
      name = "devicetree-${dtbName}";

      nativeBuildInputs = [
        pkgs.dtc
        pkgs.gcc
      ];

      buildCommand = ''
        mkdir -p $out

        cp ${dtsPath} $out/${dtsName}

        cpp -nostdinc \
          -I ${includeDir} \
          -I ${dtsFileDir} \
          -undef \
          -x assembler-with-cpp \
          ${dtsPath} \
          -o preprocessed.dts

        dtc -I dts -O dtb \
          -i ${includeDir} \
          -i ${dtsFileDir} \
          -o $out/${dtbName} \
          preprocessed.dts
      '';
    };

  dtbFile =
    if cfg.board.dts != ""
    then "${compileDtb}/${dtbName}"
    else if dtbSource.type == "kernel"
    then "${kernel}/dtbs/rockchip/${dtbName}"
    else if dtbSource.type == "git"
    then "${sourceDir}/${dtbName}"
    else "${dtbSource.localPath}/${dtbName}";

  dtsFile =
    if cfg.board.dts != ""
    then "${compileDtb}/${dtsName}"
    else null;
in {
  inherit dtbName dtsName dtbFile dtsFile;

  # Directory containing both:
  #   - ${dtsName}
  #   - ${dtbName}
  dtbOutput = compileDtb;
}

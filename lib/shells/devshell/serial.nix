{ nativePkgs }:

let
  lib = nativePkgs.lib;

  sanitizeName = name:
    builtins.replaceStrings ["-" "." " "] ["_" "_" "_"] (lib.toUpper name);
in

name: opts:

let
  envVar     = "SERIAL_${sanitizeName name}";
  baud       = toString opts.baud;
  echoArg    = lib.optionalString opts.echo ",echo=1";
  masterPath = "/run/devshell/serial-${name}-master";
  slavePath  = "/run/devshell/serial-${name}-slave";

  createSymlink = lib.optionalString (opts.symlink != null) ''
    mkdir -p "$(dirname "${opts.symlink}")"
    ln -sf "${slavePath}" "${opts.symlink}"
  '';

  startLogger = lib.optionalString (opts.logFile != null)
    "socat -u OPEN:${masterPath},rdonly OPEN:${opts.logFile},creat,append &";
in

''
  socat PTY,raw,b${baud},link=${masterPath} \
        PTY,raw,b${baud}${echoArg},link=${slavePath} &

  while [ ! -e "${slavePath}" ]; do sleep 0.05; done

  export ${envVar}="${slavePath}"
  export ${envVar}_MASTER="${masterPath}"

  ${createSymlink}
  ${startLogger}
''

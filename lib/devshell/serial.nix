{ nativePkgs, cfg }:

let
  lib = nativePkgs.lib;

  sanitizeName = name:
    builtins.replaceStrings ["-" "." " "] ["_" "_" "_"] (lib.toUpper name);
in

name: opts:

let
  envVar = "SERIAL_${sanitizeName name}";
  baud = toString opts.baud;
  echoArg = lib.optionalString opts.echo ",echo=1";

  createSymlink = lib.optionalString (opts.symlink != null) ''
    mkdir -p "$(dirname "$ROOTFS${opts.symlink}")"
    ln -sf "$DEVSHELL_TMPDIR/serial-${name}-slave" "$ROOTFS${opts.symlink}"
  '';

  startLogger = lib.optionalString (opts.logFile != null)
    "socat -u OPEN:$DEVSHELL_TMPDIR/serial-${name}-master,rdonly OPEN:$ROOTFS${opts.logFile},creat,append &";
in

''
  socat PTY,raw,b${baud},link=$DEVSHELL_TMPDIR/serial-${name}-master \
        PTY,raw,b${baud}${echoArg},link=$DEVSHELL_TMPDIR/serial-${name}-slave &
  MOCK_PIDS="$MOCK_PIDS $!"

  while [ ! -e "$DEVSHELL_TMPDIR/serial-${name}-slave" ]; do sleep 0.05; done

  export ${envVar}="$DEVSHELL_TMPDIR/serial-${name}-slave"
  export ${envVar}_MASTER="$DEVSHELL_TMPDIR/serial-${name}-master"

  ${createSymlink}
  ${startLogger}
''
{ nativePkgs, cfg }:

let
  lib = nativePkgs.lib;

  sanitizeName = name:
    builtins.replaceStrings ["-" "." " "] ["_" "_" "_"] (lib.toUpper name);
in

name: opts:

let
  envVar = "USB_${sanitizeName name}";

  symlink =
    if opts.symlink != null then opts.symlink
    else if opts.type == "serial" then "/dev/ttyACM0"
    else "/dev/usbdisk0";

  createSymlink = ''
    mkdir -p "$(dirname "$ROOTFS${symlink}")"
    ln -sf "$${envVar}" "$ROOTFS${symlink}"
  '';

  mkfsCommand =
    if opts.storageFs == "vfat"
    then "mkfs.fat -F 32"
    else "mkfs.ext4 -q";
in

if opts.type == "serial" then ''
  socat PTY,raw,link=$DEVSHELL_TMPDIR/usb-${name}-master \
        PTY,raw,link=$DEVSHELL_TMPDIR/usb-${name}-slave &
  MOCK_PIDS="$MOCK_PIDS $!"

  while [ ! -e "$DEVSHELL_TMPDIR/usb-${name}-slave" ]; do sleep 0.05; done

  export ${envVar}="$DEVSHELL_TMPDIR/usb-${name}-slave"
  export ${envVar}_MASTER="$DEVSHELL_TMPDIR/usb-${name}-master"

  ${createSymlink}

'' else if opts.type == "storage" then ''
  dd if=/dev/zero of=$DEVSHELL_TMPDIR/usb-${name}.img bs=1M count=${toString opts.storageSize} 2>/dev/null
  ${mkfsCommand} $DEVSHELL_TMPDIR/usb-${name}.img >/dev/null 2>&1

  export ${envVar}="$DEVSHELL_TMPDIR/usb-${name}.img"

  ${createSymlink}

'' else
  opts.setupScript

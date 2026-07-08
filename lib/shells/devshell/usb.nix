{ nativePkgs }:

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

  masterPath = "/run/devshell/usb-${name}-master";
  slavePath  = "/run/devshell/usb-${name}-slave";
  imgPath    = "/run/devshell/usb-${name}.img";

  createSymlink = ''
    mkdir -p "$(dirname "${symlink}")"
    ln -sf "$${envVar}" "${symlink}"
  '';

  mkfsCommand =
    if opts.storageFs == "vfat"
    then "mkfs.fat -F 32"
    else "mkfs.ext4 -q";
in

if opts.type == "serial" then ''
  socat PTY,raw,link=${masterPath} \
        PTY,raw,link=${slavePath} &

  while [ ! -e "${slavePath}" ]; do sleep 0.05; done

  export ${envVar}="${slavePath}"
  export ${envVar}_MASTER="${masterPath}"

  ${createSymlink}

'' else if opts.type == "storage" then ''
  dd if=/dev/zero of=${imgPath} bs=1M count=${toString opts.storageSize} 2>/dev/null
  ${mkfsCommand} ${imgPath} >/dev/null 2>&1

  export ${envVar}="${imgPath}"

  ${createSymlink}

'' else
  opts.setupScript

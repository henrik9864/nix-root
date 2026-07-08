{ board }:

let
  cfg = board.cfg;
  nativePkgs = cfg._nativePkgs;

  joinCmds = f: attrs:
    builtins.concatStringsSep "\n" (nativePkgs.lib.mapAttrsToList f attrs);

  shellCfg    = import ./shell.nix   { inherit nativePkgs cfg; };
  networkCmds = joinCmds (import ./network.nix { inherit nativePkgs; }) cfg.networking.interfaces;
  serialCmds  = joinCmds (import ./serial.nix  { inherit nativePkgs; }) cfg.devShell.serialDevices;
  usbCmds     = joinCmds (import ./usb.nix     { inherit nativePkgs; }) cfg.devShell.usbDevices;

  inner = import ./inner.nix {
    inherit nativePkgs cfg shellCfg serialCmds usbCmds;
  };

  entrypoint = import ./entrypoint.nix {
    inherit nativePkgs cfg networkCmds inner;
  };

in nativePkgs.mkShell {
  name = "${cfg.board.name}-rootfs-devshell";

  packages = cfg.devShell.nativePackages ++ (with nativePkgs; [
    busybox
    iproute2
    util-linux
    socat
    dosfstools
    e2fsprogs
  ]);

  shellHook = ''
    _rootfs_workdir=$(${nativePkgs.coreutils}/bin/mktemp -d "/tmp/${cfg.board.name}-rootfs-XXXXXX")
    ${nativePkgs.coreutils}/bin/cp -r --no-preserve=ownership "${board.rootfs}"/. "$_rootfs_workdir"/
    ${nativePkgs.coreutils}/bin/chmod -R u+w "$_rootfs_workdir"

    _outer_user="''${USER:-$(${nativePkgs.coreutils}/bin/id -un)}"
    {
      printf '%s:x:0:0:%s:/root:/bin/bash\n' "$_outer_user" "$_outer_user"
      printf 'root:x:0:0:root:/root:/bin/sh\n'
    } > "$_rootfs_workdir/etc/passwd"
    {
      printf '%s:x:0:\n' "$_outer_user"
      printf 'root:x:0:\n'
    } > "$_rootfs_workdir/etc/group"
    {
      printf 'passwd: files\n'
      printf 'group:  files\n'
      printf 'hosts:  files dns\n'
    } > "$_rootfs_workdir/etc/nsswitch.conf"

    export ROOTFS="$_rootfs_workdir"

    trap 'rm -rf "$_rootfs_workdir"; echo "Cleaned up rootfs workdir: $_rootfs_workdir"' EXIT

    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  Board rootfs devshell: ${cfg.board.name}"
    echo "  Target arch:           ${cfg.board.crossSystem}"
    echo "  Running natively on:   ${cfg.board.buildSystem}"
    echo "══════════════════════════════════════════════════════"
    echo ""

    ${nativePkgs.util-linux}/bin/unshare \
      --user --map-root-user \
      --net --mount --uts --ipc --cgroup \
      --pid --fork \
      -- ${entrypoint}

    exit $?
  '';
}

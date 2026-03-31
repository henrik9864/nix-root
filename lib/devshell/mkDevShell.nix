{ board }:

let
  cfg = board.cfg;
  nativePkgs = cfg._nativePkgs;

  joinCmds = f: attrs:
    builtins.concatStringsSep "\n" (nativePkgs.lib.mapAttrsToList f attrs);

  shellCfg    = import ./shell.nix    { inherit nativePkgs cfg; };
  networkCmds = joinCmds (import ./network.nix { inherit nativePkgs; }) cfg.devShell.networkInterfaces;
  serialCmds  = joinCmds (import ./serial.nix  { inherit nativePkgs cfg; }) cfg.devShell.serialDevices;
  usbCmds     = joinCmds (import ./usb.nix     { inherit nativePkgs cfg; }) cfg.devShell.usbDevices;

  netnsWrapper = nativePkgs.writeShellScript "${cfg.board.name}-netns-wrapper" ''
    export PATH="${nativePkgs.iproute2}/bin:${nativePkgs.socat}/bin:${nativePkgs.coreutils}/bin:$PATH"

    ip link set lo up
    ${networkCmds}

    DEVSHELL_TMPDIR=$(mktemp -d "/tmp/${cfg.board.name}-devshell-XXXXXX")
    export DEVSHELL_TMPDIR
    MOCK_PIDS=""

    ${serialCmds}
    ${usbCmds}

    cleanup() {
      kill $MOCK_PIDS 2>/dev/null
      rm -rf "$DEVSHELL_TMPDIR"
    }
    trap cleanup EXIT

    export INPUTRC=${shellCfg.inputrc}
    ${nativePkgs.bashInteractive}/bin/bash --rcfile ${shellCfg.bashrc} -i

    exit $?
  '';

in nativePkgs.mkShell {
  name = "${cfg.board.name}-rootfs-devshell";

  packages = cfg.rootfs.extraPackages ++ (with nativePkgs; [
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
    export ROOTFS="$_rootfs_workdir"

    cleanup() {
      rm -rf "$_rootfs_workdir"
      echo "Cleaned up rootfs workdir: $_rootfs_workdir"
    }
    trap cleanup EXIT

    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  Board rootfs devshell: ${cfg.board.name}"
    echo "  Target arch:           ${cfg.board.crossSystem}"
    echo "  Running natively on:   ${cfg.board.buildSystem}"
    echo "══════════════════════════════════════════════════════"
    echo ""

    cd "$ROOTFS"
    unshare --user --map-root-user --net -- ${netnsWrapper}

    exit $?
  '';
}
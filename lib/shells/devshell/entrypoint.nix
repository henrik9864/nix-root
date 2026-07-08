{ nativePkgs, cfg, networkCmds, inner }:

nativePkgs.writeShellScript "${cfg.board.name}-entrypoint" ''
  export PATH="${nativePkgs.iproute2}/bin:${nativePkgs.util-linux}/bin:${nativePkgs.coreutils}/bin:${nativePkgs.busybox}/bin:$PATH"

  hostname ${cfg.networking.hostName}

  ip link set lo up
  ${networkCmds}

  mount --make-rprivate /

  mount -t proc proc "$ROOTFS/proc"

  mount --rbind /dev "$ROOTFS/dev"
  mount --make-rslave "$ROOTFS/dev"

  mkdir -p "$ROOTFS/nix/store"
  mount --bind /nix/store "$ROOTFS/nix/store"
  mount -o remount,ro "$ROOTFS/nix/store" 2>/dev/null || true

  mkdir -p "$ROOTFS/run/devshell"

  exec chroot "$ROOTFS" ${inner}
''

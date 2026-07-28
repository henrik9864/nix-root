{
  nativePkgs,
  cfg,
  networkCmds,
  inner,
}:
nativePkgs.writeShellScript "${cfg.board.name}-entrypoint" ''
  export PATH="${nativePkgs.iproute2}/bin:${nativePkgs.util-linux}/bin:${nativePkgs.coreutils}/bin:${nativePkgs.busybox}/bin:$PATH"

  hostname ${cfg.networking.hostName}

  ip link set lo up
  ${networkCmds}

  mount --make-rprivate /

  mount -t proc proc "$ROOTFS/proc"

  mount -t tmpfs devtmpfs "$ROOTFS/dev" -o mode=0755,size=1m

  for _dev in null zero full random urandom tty; do
    [ -e "/dev/$_dev" ] && touch "$ROOTFS/dev/$_dev" && mount --bind "/dev/$_dev" "$ROOTFS/dev/$_dev" || true
  done

  ln -sf /proc/self/fd   "$ROOTFS/dev/fd"
  ln -sf /proc/self/fd/0 "$ROOTFS/dev/stdin"
  ln -sf /proc/self/fd/1 "$ROOTFS/dev/stdout"
  ln -sf /proc/self/fd/2 "$ROOTFS/dev/stderr"

  mkdir -p "$ROOTFS/dev/pts"
  mount -t devpts devpts "$ROOTFS/dev/pts" -o newinstance,ptmxmode=0666,mode=0620

  ln -sf pts/ptmx "$ROOTFS/dev/ptmx"

  mkdir -p "$ROOTFS/nix/store"
  mount --bind /nix/store "$ROOTFS/nix/store"
  mount -o remount,ro "$ROOTFS/nix/store" 2>/dev/null || true

  mkdir -p "$ROOTFS/run/devshell"

  exec chroot "$ROOTFS" ${inner}
''

{
  pkgs,
  nativePkgs,
  cfg,
}: let
  lib = nativePkgs.lib;

  busybox = pkgs.busybox.override {
    enableStatic = true;
  };

  # ── Packages ──────────────────────────────────────
  extraPkgCommands = builtins.concatStringsSep "\n" (
    map (pkg: ''
      for bin in ${pkg}/bin/*; do
        [ -f "$bin" ] && cp "$bin" $out/bin/ && chmod +x $out/bin/$(basename "$bin")
      done
      for sbin in ${pkg}/sbin/*; do
        [ -f "$sbin" ] && cp "$sbin" $out/sbin/ && chmod +x $out/sbin/$(basename "$sbin")
      done
    '')
    cfg.environment.systemPackages
  );

  # ── Users & groups ────────────────────────────────
  passwdFile = builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: u: "${name}:x:${toString u.uid}:${toString (cfg.users.groups.${u.group}.gid or 0)}:${u.description}:${u.home}:${u.shell}"
    )
    cfg.users.users
  );

  groupFile = builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: g: "${name}:x:${toString g.gid}:"
    )
    cfg.users.groups
  );

  # ── Networking ────────────────────────────────────
  resolvConf = builtins.concatStringsSep "\n" (
    map (ns: "nameserver ${ns}") cfg.networking.nameservers
  );

  networkScript = builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (
      iface: opts:
        if opts.useDHCP
        then "udhcpc -i ${iface} -b -q &"
        else if opts.address != null
        then
          ''
            ip addr add ${opts.address} dev ${iface}
            ip link set ${iface} up
          ''
          + lib.optionalString (opts.gateway != null)
          "ip route add default via ${opts.gateway} dev ${iface}\n"
        else ""
    )
    cfg.networking.interfaces
  );

  # ── environment.etc ───────────────────────────────
  etcCommands = builtins.concatStringsSep "\n" (
    lib.mapAttrsToList (
      path: opts: let
        fullPath = "/etc/${path}";
        dir = builtins.dirOf fullPath;
        writeContent =
          if opts.text != null
          then ''            cat > $out${fullPath} << 'NIXFILEEOF'
            ${opts.text}
            NIXFILEEOF''
          else if opts.source != null
          then "cp ${opts.source} $out${fullPath}"
          else builtins.throw "environment.etc.\"${path}\": must set either 'text' or 'source'";
      in ''
        mkdir -p $out${dir}
        ${writeContent}
        chmod ${opts.mode} $out${fullPath}
      ''
    )
    cfg.environment.etc
  );

  # ── Overlay ───────────────────────────────────────
  overlayCommands = lib.optionalString (cfg.rootfs.overlay != null) ''
    echo ":: Applying rootfs overlay ::"
    cp -a ${cfg.rootfs.overlay}/. $out/
  '';

  # ── Init script with networking ───────────────────
  initScript = ''
    #!/bin/sh
    mount -t proc  none /proc
    mount -t sysfs none /sys
    mount -t devtmpfs devtmpfs /dev 2>/dev/null

    echo "INIT: post-devtmpfs" > /dev/kmsg 2>/dev/null

    if [ ! -c /dev/console ]; then
      echo "INIT: no console, using tmpfs" > /dev/kmsg 2>/dev/null
      mount -t tmpfs tmpfs /dev
      mknod /dev/console c 5 1
      mknod /dev/null    c 1 3
      mknod /dev/kmsg    c 1 11
      mknod /dev/ttyS2   c 4 66
    fi

    echo "INIT: console exists? $([ -c /dev/console ] && echo yes || echo no)" > /dev/kmsg 2>/dev/null
    echo "INIT: before exec redirect" > /dev/kmsg 2>/dev/null

    exec </dev/console >/dev/console 2>&1

    echo "INIT: after redirect, reached Boot OK" > /dev/kmsg 2>/dev/null
    echo ":: Boot OK ::"
    hostname ${cfg.networking.hostName}
    ${networkScript}

    while true; do
      setsid cttyhack /bin/sh </dev/console >/dev/console 2>&1 || /bin/sh </dev/console >/dev/console 2>&1
    done
  '';
in
  nativePkgs.stdenv.mkDerivation {
    name = "${cfg.board.name}-rootfs-${pkgs.stdenv.hostPlatform.config}";

    buildCommand = ''
          # ── Directory layout ───────────────────────────────
          mkdir -p $out/{bin,sbin,etc,proc,sys,dev,tmp,mnt,root}

          # ── Busybox applet symlinks (skip busybox itself) ──
          for applet in ${nativePkgs.busybox}/bin/*; do
            name=$(basename "$applet")
            [ "$name" = "busybox" ] && continue
            ln -sf /bin/busybox $out/bin/$name
          done

          # ── Real busybox binary (copied last, never overwritten) ──
          cp ${busybox}/bin/busybox $out/bin/busybox
          chmod +x $out/bin/busybox

          # ── Extra packages ─────────────────────────────────
          ${extraPkgCommands}

          # ── /etc files ─────────────────────────────────────
          echo "${passwdFile}"  > $out/etc/passwd
          echo "${groupFile}"   > $out/etc/group
          echo "${resolvConf}"  > $out/etc/resolv.conf
          echo "${cfg.networking.hostName}" > $out/etc/hostname

          # ── Init script ────────────────────────────────────
          cat > $out/init << 'NIXEOF'
      ${initScript}
      NIXEOF
          chmod +x $out/init

          # ── Overlay ────────────────────────────────────────
          ${overlayCommands}

          # ── environment.etc (highest priority) ─────────────
          ${etcCommands}

          # ── Extra commands ─────────────────────────────────
          ${cfg.rootfs.extraCommands}
    '';
  }

{ pkgs, nativePkgs, cfg }:

let
  busybox = pkgs.busybox.override {
    enableStatic = true;
  };

  extraPkgCommands = builtins.concatStringsSep "\n" (
    map (pkg: ''
      for bin in ${pkg}/bin/*; do
        [ -f "$bin" ] && cp "$bin" $out/bin/ && chmod +x $out/bin/$(basename "$bin")
      done
      for sbin in ${pkg}/sbin/*; do
        [ -f "$sbin" ] && cp "$sbin" $out/sbin/ && chmod +x $out/sbin/$(basename "$sbin")
      done
    '') cfg.rootfs.extraPackages
  );

  # Generate shell commands for rootfs.overlay
  overlayCommands = if cfg.rootfs.overlay != null then ''
    echo ":: Applying rootfs overlay ::"
    cp -a ${cfg.rootfs.overlay}/. $out/
  '' else "";

  # Generate shell commands for rootfs.files
  fileCommands = builtins.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (path: opts:
      let
        dir = builtins.dirOf path;
        writeContent =
          if opts.text != null then
            ''cat > $out${path} << 'NIXFILEEOF'
${opts.text}
NIXFILEEOF''
          else if opts.source != null then
            "cp ${opts.source} $out${path}"
          else
            builtins.throw "rootfs.files.\"${path}\": must set either 'text' or 'source'";
      in ''
        mkdir -p $out${dir}
        ${writeContent}
        chmod ${opts.mode} $out${path}
      ''
    ) cfg.rootfs.files
  );

in

nativePkgs.stdenv.mkDerivation {
  name = "${cfg.board.name}-rootfs-${pkgs.stdenv.hostPlatform.config}";

  buildCommand = ''
    # ── Directory layout ───────────────────────────────
    mkdir -p $out/{bin,sbin,etc,proc,sys,dev,tmp,mnt,root}

    # ── Busybox ────────────────────────────────────────
    cp ${busybox}/bin/busybox $out/bin/busybox
    chmod +x $out/bin/busybox

    for applet in ${nativePkgs.busybox}/bin/*; do
      ln -sf /bin/busybox $out/bin/$(basename "$applet")
    done

    # ── Extra packages ─────────────────────────────────
    ${extraPkgCommands}

    # ── Minimal /etc ───────────────────────────────────
    echo "${cfg.rootfs.passwd}"  > $out/etc/passwd
    echo "${cfg.rootfs.group}"   > $out/etc/group
    echo "${cfg.rootfs.resolv}"  > $out/etc/resolv.conf

    # ── Init script ────────────────────────────────────
    cat > $out/init << 'NIXEOF'
${cfg.rootfs.initScript}
NIXEOF
    chmod +x $out/init

    # ── Overlay (applied first) ────────────────────────
    ${overlayCommands}

    # ── Declarative files (applied last, highest priority) ──
    ${fileCommands}

    # ── Extra commands ─────────────────────────────────
    ${cfg.rootfs.extraCommands}
  '';
}
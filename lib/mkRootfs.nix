{ pkgs, cfg }:

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
in

pkgs.stdenv.mkDerivation {
  name = "${cfg.board.name}-rootfs";

  buildCommand = ''
    # ── Directory layout ───────────────────────────────
    mkdir -p $out/{bin,sbin,etc,proc,sys,dev,tmp,mnt,root}

    # ── Busybox ────────────────────────────────────────
    cp ${busybox}/bin/busybox $out/bin/busybox
    chmod +x $out/bin/busybox

    ${busybox}/bin/busybox --list | while read applet; do
      ln -sf /bin/busybox $out/bin/$applet
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

    # ── Extra commands ─────────────────────────────────
    ${cfg.rootfs.extraCommands}
  '';
}
{ nativePkgs, cfg, shellCfg, serialCmds, usbCmds }:

nativePkgs.writeShellScript "${cfg.board.name}-inner" ''
  export PATH="${nativePkgs.iproute2}/bin:${nativePkgs.socat}/bin:${nativePkgs.coreutils}/bin:${nativePkgs.busybox}/bin:$PATH"
  export HOME=/root
  export INPUTRC=${shellCfg.inputrc}

  ${serialCmds}
  ${usbCmds}

  ${cfg.rootfs.extraInitCommands}

  exec ${nativePkgs.bashInteractive}/bin/bash --rcfile ${shellCfg.bashrc} -i
''

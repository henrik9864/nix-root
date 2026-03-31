{
  description = "Embedded Linux image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-custom.url = "path:./pkgs";
  };

  outputs = { self, nixpkgs, pkgs-custom }:
  let
    overlays = [
      (final: prev: import ./pkgs/default.nix { callPackage = final.callPackage; })
    ];

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      inherit overlays;
    };

    mkBoard = { boardModule, outputTarget }:
    let
      eval = import ./lib/options/options.nix {
        inherit nixpkgs overlays;
        modules = [
          boardModule
          { output.target = outputTarget; }
        ];
      };

      cfg = eval.config;

      bootloader = cfg.bootloader.package;
      kernel     = import ./lib/kernel/mkKernel.nix  { pkgs = cfg._pkgs;                               inherit cfg; };
      rootfs     = import ./lib/rootfs/mkRootfs.nix  { pkgs = cfg._pkgs; nativePkgs = cfg._nativePkgs; inherit cfg; };
      initrd     = import ./lib/initrd/mkInitrd.nix  { pkgs = cfg._nativePkgs;                         inherit rootfs; };
      image      = import ./lib/image/mkImage.nix   { pkgs = cfg._nativePkgs; inherit cfg bootloader kernel initrd rootfs; };
    in {
      inherit kernel rootfs initrd image cfg;
    };

    mkDevShell = { board }:
    let
      cfg = board.cfg;
      nativePkgs = cfg._nativePkgs;

      interfaces = cfg.devShell.networkInterfaces;

      ifUpCommands = builtins.concatStringsSep "\n" (
        nativePkgs.lib.mapAttrsToList (name: opts:
          let
            macCmd = if opts.mac != null
              then "ip link set dev ${name} address ${opts.mac}"
              else "";
            gwCmd = if opts.gateway != null
              then "ip route add default via ${opts.gateway} dev ${name} 2>/dev/null || true"
              else "";
          in ''
            ip link add ${name} type dummy
            ${macCmd}
            ip addr add ${opts.address} dev ${name}
            ip link set dev ${name} up
            ${gwCmd}
          ''
        ) interfaces
      );

      netnsWrapper = nativePkgs.writeShellScript "${cfg.board.name}-netns-wrapper" ''
        export PATH="${nativePkgs.iproute2}/bin:$PATH"

        ip link set lo up

        ${ifUpCommands}

        export PS1=$'\001\033[1;32m\002\\u@\\h\001\033[0m\002 \001\033[1;34m\002\\w\001\033[0m\002\$ '
        export HISTFILE="$ROOTFS/.bash_history"
        exec bash --norc --noprofile -i
      '';

    in nativePkgs.mkShell {
      name = "${cfg.board.name}-rootfs-devshell";

      packages = cfg.rootfs.extraPackages ++ [
        nativePkgs.busybox
        nativePkgs.iproute2
        nativePkgs.util-linux
      ];

      shellHook = ''
        _rootfs_workdir=$(${nativePkgs.coreutils}/bin/mktemp -d "/tmp/${cfg.board.name}-rootfs-XXXXXX")
        ${nativePkgs.coreutils}/bin/cp -r --no-preserve=ownership "${board.rootfs}"/. "$_rootfs_workdir"/
        ${nativePkgs.coreutils}/bin/chmod -R u+w "$_rootfs_workdir"
        export ROOTFS="$_rootfs_workdir"

        _cleanup_rootfs() {
          if [ -n "$_rootfs_workdir" ] && [ -d "$_rootfs_workdir" ]; then
            rm -rf "$_rootfs_workdir"
            echo "Cleaned up rootfs workdir: $_rootfs_workdir"
          fi
        }
        trap _cleanup_rootfs EXIT

        echo ""
        echo "══════════════════════════════════════════════════════"
        echo "  Board rootfs devshell: ${cfg.board.name}"
        echo "  Target arch:           ${cfg.board.crossSystem}"
        echo "  Running natively on:   ${cfg.board.buildSystem}"
        echo "══════════════════════════════════════════════════════"
        echo ""
        echo "  The workdir is automatically cleaned up on exit."
        echo ""

        cd "$ROOTFS"

        exec unshare --user --map-root-user --net -- ${netnsWrapper}
      '';
    };

    boardRegistry = import ./boards/boards.nix;

    boards = builtins.mapAttrs (_: targets:
      builtins.mapAttrs (_: args: mkBoard args) targets
    ) boardRegistry;

  in {
    packages.x86_64-linux =
      builtins.mapAttrs (_: targets:
        builtins.mapAttrs (_: board: board.image) targets
      ) boards;

    devShells.x86_64-linux =
      builtins.mapAttrs (_: targets:
        let
          firstBoard = builtins.head (builtins.attrValues targets);
        in mkDevShell { board = firstBoard; }
      ) boards;
  };
}

# TODO: Add option to create moch devices(serial/usb) and interfaces (ethernet)
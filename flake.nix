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

    in nativePkgs.mkShell {
      name = "${cfg.board.name}-rootfs-devshell";

      packages = cfg.rootfs.extraPackages ++ [
        nativePkgs.busybox
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

        export PS1="(${cfg.board.name}-rootfs) \[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "

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